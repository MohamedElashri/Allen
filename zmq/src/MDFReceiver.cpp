#include <fcntl.h>

#include <iostream>
#include <string>
#include <algorithm>
#include <thread>

#ifdef USE_BOOST_FILESYSTEM
#include <boost/filesystem.hpp>
#else
#include <filesystem>
#endif

#include <boost/program_options.hpp>
#include <boost/format.hpp>

#include <ZeroMQSvc.h>
#include "Timer.h"

#include <read_mdf.hpp>

namespace {
  using namespace std::string_literals;
  namespace po = boost::program_options;

#ifdef USE_BOOST_FILESYSTEM
  namespace fs = boost::filesystem;
#else
  namespace fs = std::filesystem;
#endif
}

void timer(std::string connection) {
  zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(control, zmq::LINGER, 0);
  control.connect(connection);

  zmq::pollitem_t items[] = {control, 0, zmq::POLLIN, 0};
  while (true) {
    zmq::poll(&items[0], 1, 500);
    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(control);
      if (msg == "DONE") break;
    }
    zmqSvc().send(control, "TICK");
  }
}

int main(int argc, char* argv[]) {

  std::string directory;
  std::string file_pattern;
  unsigned int request_port;
  unsigned int data_port;
  unsigned int file_size;
  unsigned int max_files;

  // Declare the supported options.
  po::options_description desc("Allowed options");
  desc.add_options()
    ("help,h", "produce help message")
    ("directory", po::value<std::string>(&directory), "output directory")
    ("filename,f", po::value<std::string>(&file_pattern)->default_value("AllenOutput_%1$03d.mdf"), "filename pattern")
    ("request-port", po::value<unsigned int>(&request_port)->default_value(35000u), "port on which to listen to connection requests")
    ("data-port", po::value<unsigned int>(&data_port)->default_value(40000u), "port on which to listen to connection requests")
    ("file-size,s", po::value<unsigned int>(&file_size)->default_value(10240u), "File size [MB]")
    ("max-files", po::value<unsigned int>(&max_files)->default_value(10), "Maximum number of files")
    ;

  po::positional_options_description p;
  p.add("directory", 1);

  po::variables_map vm;
  po::store(po::command_line_parser(argc, argv).
            options(desc).positional(p).run(), vm);
  po::notify(vm);

  if (vm.count("help")) {
    std::cout << desc << "\n";
    return 1;
  }

  // Create a control socket and connect it.
  zmq::socket_t server = zmqSvc().socket(zmq::REP);
  zmq::setsockopt(server, zmq::LINGER, 0);
  server.bind("tcp://*:"s + std::to_string(request_port));

  // Create socket to monitor the output rate.
  zmq::socket_t rate_socket = zmqSvc().socket(zmq::PUB);
  zmq::setsockopt(rate_socket, zmq::LINGER, 0);
  rate_socket.bind("tcp://*:"s + std::to_string(request_port + 1));

  // Create a control socket and connect it.
  std::string tick_connection = "inproc://tick";
  zmq::socket_t tick = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(tick, zmq::LINGER, 0);
  tick.bind(tick_connection);

  std::thread tick_thread{timer, tick_connection};

  std::vector<zmq::pollitem_t> items(2);
  items.reserve(10);
  items[0] = {server, 0, zmq::POLLIN, 0};
  items[1] = {tick, 0, zmq::POLLIN, 0};

  std::vector<std::tuple<std::string, zmq::socket_t>> clients;

  size_t size_bytes = 0;

  std::optional<Allen::IO> output_file{};
  unsigned int n_file = 0;
  fs::path filename{};
  bool stopping = false;
  unsigned int n_wait = 0;
  std::tuple<size_t, size_t> n_written{};

  std::vector<std::tuple<std::string, size_t>> written;

  while (!stopping || (stopping && !clients.empty()) || (stopping && n_wait < 10)) {

    // Check if there are messages
    zmq::poll(&items[0], items.size(), -1);

    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(server);
      if (msg == "PORT") {
        auto client_id = zmqSvc().receive<std::string>(server);
        auto port = data_port++;
        auto& [client_name, data_socket] = clients.emplace_back(std::move(client_id), zmqSvc().socket(zmq::PAIR));
        zmq::setsockopt(data_socket, zmq::LINGER, 500);
        zmq::setsockopt(data_socket, zmq::SNDTIMEO, 500);
        data_socket.bind("tcp://*:"s + std::to_string(port));
        items.emplace_back(zmq::pollitem_t{data_socket, 0, zmq::POLLIN, 0});
        zmqSvc().send(server, std::to_string(port));
        std::cout << "Client " << client_name << " given port " << port << "\n";
      }
      else if (msg == "EXIT") {
        zmqSvc().send(server, "OK");

        for (auto& [name, socket] : clients) {
          try {
            zmqSvc().send(socket, "RECEIVER_STOP");
          } catch (ZMQ::TimeOutException const&) {
          }
        }
        n_wait = 0;
        stopping = true;
      }
      else if (msg == "CLIENT_EXIT") {
        auto id = zmqSvc().receive<std::string>(server);
        zmqSvc().send(server, "OK");
        auto it = std::find_if(clients.begin(), clients.end(), [id] (const auto& entry) { return std::get<0>(entry) == id; });
        if (it != clients.end()) {
          auto& [client_id, socket] = *it;
          std::cout << client_id << " is exiting\n";
          clients.erase(it);
        }
      }
      else if (msg == "REPORT") {
        for (auto [filename, size] : written) {
          zmqSvc().send(server, filename, zmq::SNDMORE);
          zmqSvc().send(server, std::to_string(size), zmq::SNDMORE);
        }
        if (!output_file) {
          zmqSvc().send(server, "Waiting for data");
        } else {
          zmqSvc().send(server, filename.string(), zmq::SNDMORE);
          zmqSvc().send(server, std::to_string(size_bytes));
        }
      }
    }

    if (items[1].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(tick);
      if (msg == "TICK") ++n_wait;

      if (n_wait == 10 && !stopping) {
        auto& [bytes_written, n_events] = n_written;
        auto dt = double{n_wait * 0.5};
        auto event_rate = n_events / dt;
        auto data_rate =  bytes_written / (1024 * 1024 * dt);
        zmqSvc().send(rate_socket, std::to_string(event_rate));
        std::cout << "Wrote " << n_events << " events (" << event_rate << " events/s) and "
                  << bytes_written / (1024 * 1024) << " MB (" << data_rate << " MB/s)\n";
        n_written = {0, 0};
        n_wait = 0;
      }
    }

    for (size_t i = 0; i < items.size() - 2; ++i) {
      if (items[i + 2].revents & zmq::POLLIN) {
        auto& client_socket = std::get<1>(clients[i]);
        auto msg = zmqSvc().receive<std::string>(client_socket);
        if (msg == "EVENT") {
          if (!output_file) {
            n_file = (n_file == max_files) ? 1 : n_file + 1;
            filename = fs::path{directory} / (boost::format{file_pattern} % n_file).str();
            output_file = MDF::open(filename.string(), O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
            if (!output_file->good) {
              std::cout << "Failed to open output file " << filename << ".\n";
              exit(1);
            } else {
              std::cout << "Opened " << filename.string() << " for writing.\n";
            }
          }

          auto msg = zmqSvc().receive<zmq::message_t>(client_socket);
          output_file->write(static_cast<char const*>(msg.data()), msg.size());
          size_bytes += msg.size();
          auto& [bytes_written, n_events] = n_written;
          bytes_written += msg.size();
          ++n_events;
          if (size_bytes > size_t{file_size} * 1024 * 1024) {
            output_file->close();
            output_file.reset();
            written.emplace_back(filename.string(), size_bytes);
            size_bytes = 0;
          }
        }
        else if (msg == "OK") {
          std::cout << std::get<0>(clients[i]) << " acknowledged stop\n";
          clients.erase(clients.begin() + i);
          items.erase(items.begin() + i + 2);
        }
      }
    }
  }

  // Exit the tick thread;
  zmqSvc().send(tick, "DONE");
  tick_thread.join();

  if (output_file) {
    output_file->close();
    written.emplace_back(filename.string(), size_bytes);
  }
  if (!written.empty()) std::cout << "Wrote:\n";
  for (auto [filename, size] : written) {
    std::cout << filename << " " << size << "\n";
  }
}
