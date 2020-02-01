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

#include <IZeroMQSvc.h>
#include "Timer.h"

#include <read_mdf.hpp>
#include <raw_helpers.hpp>

namespace {
  using namespace std::string_literals;
  namespace po = boost::program_options;

#ifdef USE_BOOST_FILESYSTEM
  namespace fs = boost::filesystem;
#else
  namespace fs = std::filesystem;
#endif

  using Buffers = std::array<std::tuple<std::vector<char>, unsigned int>, 3>;
}

void write_files(std::string connection, std::string const& directory,
                 std::string const& file_pattern, unsigned int const max_files,
                 unsigned int const max_file_size, bool const discard,
                 Buffers const& buffers)
{

  zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(control, zmq::LINGER, 0);
  control.connect(connection);

  std::optional<Allen::IO> output_file{};
  unsigned int n_file = 0;
  fs::path filename{};
  bool good = true;
  size_t size_bytes = 0;

  zmq::pollitem_t items[] = {{control, 0, zmq::POLLIN, 0}};
  while (true) {
    zmqSvc().poll(&items[0], 1, -1);
    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(control);
      if (msg == "DONE") {
        if (!discard) {
          zmqSvc().send(control, filename.string(), zmq::SNDMORE);
          zmqSvc().send(control, size_bytes);
        }
        break;
      } else if (msg == "WRITE" && good) {
        size_t buffer = zmqSvc().receive<size_t>(control);

        if (!discard && !output_file) {
          n_file = (n_file == max_files) ? 1 : n_file + 1;
          filename = fs::path{directory} / (boost::format{file_pattern} % n_file).str();
          output_file = MDF::open(filename.string(), O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | O_DIRECT);
          size_bytes = 0;
          if (!output_file->good) {
            std::cout << "Failed to open output file " << filename << ".\n";
            good = false;
          } else {
            std::cout << "Opened " << filename.string() << " for writing.\n";
          }
        }

        auto const& [event_buffer, offset] = buffers[buffer];

        auto const skip = 4 * sizeof(int);
        char const* data = event_buffer.data();
        while(data - event_buffer.data() < offset) {
          auto* header = reinterpret_cast<LHCb::MDFHeader const*>(data);
          auto const event_size = header->recordSize();
          if (header->checkSum() != 0) {
            auto c = LHCb::genChecksum(1, data + skip, event_size - skip);
            if (header->checkSum() != c) {
              std::cout << "Checksum failed.\n";
            }
          }
          data += event_size;
        }

        if (!discard) {
          if (output_file->good) {
          output_file->write(event_buffer.data(), offset);
          size_bytes += offset;
          } else {
            zmqSvc().send(control, "ERROR");
          }
        }

        // reply "FREE" i_buffer
        zmqSvc().send(control, "FREE", zmq::SNDMORE);
        zmqSvc().send(control, buffer);


        if (!discard && output_file->good) {
          if (size_bytes > size_t{max_file_size} * 1024 * 1024) {
            output_file->close();
            output_file.reset();
            zmqSvc().send(control, "CLOSED", zmq::SNDMORE);
            zmqSvc().send(control, filename.string(), zmq::SNDMORE);
            zmqSvc().send(control, size_bytes);
            size_bytes = 0;
          }
        }
      }
    }
  }

  if (output_file) {
    output_file->close();
  }
}

void timer(std::string connection) {
  zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(control, zmq::LINGER, 0);
  control.connect(connection);

  zmq::pollitem_t items[] = {{control, 0, zmq::POLLIN, 0}};
  while (true) {
    zmqSvc().poll(&items[0], 1, 500);
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
  unsigned int buffer_size;
  bool discard;

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
    ("buffer-size,b", po::value<unsigned int>(&buffer_size)->default_value(32), "Receive buffer size [MB]")
    ("discard,d", po::value<bool>(&discard)->default_value(false), "Discard events instead of writing them to disk")
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

  // Create a server socket and connect it.
  zmq::socket_t server = zmqSvc().socket(zmq::REP);
  zmq::setsockopt(server, zmq::LINGER, 0);
  server.bind("tcp://*:"s + std::to_string(request_port));

  // Create socket to monitor the output rate.
  zmq::socket_t rate_socket = zmqSvc().socket(zmq::PUB);
  zmq::setsockopt(rate_socket, zmq::LINGER, 0);
  rate_socket.bind("tcp://*:"s + std::to_string(request_port + 1));

  // Create a control socket for the tick thread and bind it.
  std::string tick_connection = "inproc://tick";
  zmq::socket_t tick_socket = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(tick_socket, zmq::LINGER, 0);
  tick_socket.bind(tick_connection);

  // Start tick thread
  std::thread tick_thread{timer, tick_connection};

  // Storage for incoming events
  Buffers buffers;
  std::array<bool, buffers.size()> writable;
  writable.fill(true);
  std::array<bool, buffers.size()> submitted;
  submitted.fill(false);
  size_t buffer = 0;
  bool error = false;

  // Create a control socket for the writer thread and bind it.
  std::string writer_connection = "inproc://writer";
  zmq::socket_t writer_socket = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(writer_socket, zmq::LINGER, 0);
  writer_socket.bind(writer_connection);

  // Start writing thread
  std::thread writer_thread{[writer_connection, directory, file_pattern,
                             max_files, file_size, discard, &buffers] {
                              write_files(writer_connection, directory, file_pattern, max_files, file_size, discard, buffers);
                            }};

  std::vector<zmq::pollitem_t> items(3);
  items.reserve(13);
  items[0] = {server, 0, zmq::POLLIN, 0};
  items[1] = {tick_socket, 0, zmq::POLLIN, 0};
  items[2] = {writer_socket, 0, zmq::POLLIN, 0};

  std::vector<std::tuple<std::string, zmq::socket_t>> clients;

  bool stopping = false;
  unsigned int n_wait = 0;
  std::tuple<size_t, size_t> n_received{};
  std::tuple<size_t, size_t> n_dropped{};

  for (auto& [buffer, offset] : buffers) {
    buffer.resize(buffer_size * 1024 * 1024);
    offset = 0;
  }

  std::vector<std::tuple<std::string, size_t>> written;

  auto get_buffer = [&writable, &submitted, &buffers, &writer_socket](size_t buffer, size_t msg_size) -> size_t {
    if (writable[buffer]) {
      auto& [event_buffer, offset] = buffers[buffer];
      if (offset + msg_size < event_buffer.size()) {
        // Current buffer is good for writing
        return buffer;
      } else if (!submitted[buffer]) {
        // Event doesn't fit in current buffer, send it for writing
        zmqSvc().send(writer_socket, "WRITE", zmq::SNDMORE);
        zmqSvc().send(writer_socket, buffer);
        submitted[buffer] = true;
        writable[buffer] = false;
      }
    }

    // Find new buffer
    size_t i_buffer = 0;
    for (; i_buffer < buffers.size(); ++i_buffer) {
      if (writable[i_buffer]) break;
    }
    if (i_buffer < buffers.size()) {
      std::get<1>(buffers[i_buffer]) = 0;
      return i_buffer;
    } else {
      return 0;
    }
  };

  while (!stopping || (stopping && !clients.empty()) || (stopping && n_wait < 10)) {

    // Check if there are messages
    zmqSvc().poll(&items[0], items.size(), -1);

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
          items.erase(items.begin() + std::distance(clients.begin(), it) + 3);
          clients.erase(it);
        }
      }
      else if (msg == "REPORT") {
        for (size_t i = 0; i < written.size(); ++i) {
          auto const& [filename, size] = written[i];
          zmqSvc().send(server, filename, zmq::SNDMORE);
          zmqSvc().send(server, std::to_string(size), (i < written.size() - 1) ? zmq::SNDMORE : 0);
        }
        if (written.empty()) {
          zmqSvc().send(server, "Waiting for data");
        }
      }
    }

    if (items[1].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(tick_socket);
      if (msg == "TICK") ++n_wait;

      if (n_wait == 10 && !stopping) {
        auto& [bytes_received, n_events] = n_received;
        auto dt = double{n_wait * 0.5};
        auto event_rate = n_events / dt;
        auto mb_received = bytes_received / (1024 * 1024);
        auto data_rate =   mb_received /dt;
        zmqSvc().send(rate_socket, std::to_string(event_rate));
        std::cout << "Received " << n_events << " events (" << event_rate << " events/s) and "
                  << mb_received << " MB (" << data_rate << " MB/s)\n";
        n_received = {0, 0};
        n_wait = 0;
      }
    }

    if (items[2].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(writer_socket);
      if (msg == "FREE") {
        auto free_buffer = zmqSvc().receive<size_t>(writer_socket);
        submitted[free_buffer] = false;
        writable[free_buffer] = true;
      } else if (msg == "CLOSED") {
        auto filename = zmqSvc().receive<std::string>(writer_socket);
        auto bytes_written = zmqSvc().receive<size_t>(writer_socket);
        written.emplace_back(filename, bytes_written);
      } else if (msg == "ERROR") {
        std::cout << "Received error from writing thread.\n";
        error = true;
        break;
      }
    }

    for (size_t i = 0; i < items.size() - 3; ++i) {
      if (items[i + 3].revents & zmq::POLLIN) {
        auto& client_socket = std::get<1>(clients[i]);
        auto msg = zmqSvc().receive<std::string>(client_socket);
        if (msg == "EVENT") {
          auto msg = zmqSvc().receive<zmq::message_t>(client_socket);
          // Get buffer to write to
          buffer = get_buffer(buffer, msg.size());
          if (writable[buffer]) {
            auto& [event_buffer, offset] = buffers[buffer];
            ::memcpy(&event_buffer[0] + offset, msg.data(), msg.size());
            offset += msg.size();
          } else {
            auto& [bytes_dropped, dropped] = n_dropped;
            bytes_dropped += msg.size();
            dropped += 1;
          }
          auto& [bytes_received, n_events] = n_received;
          bytes_received += msg.size();
          ++n_events;
        }
        else if (msg == "OK") {
          std::cout << std::get<0>(clients[i]) << " acknowledged stop\n";
          clients.erase(clients.begin() + i);
          items.erase(items.begin() + i + 3);
        }
      }
    }
  }

  // Exit the tick thread;
  zmqSvc().send(tick_socket, "DONE");
  tick_thread.join();

  // Exit the writing thread
  zmqSvc().send(writer_socket, "DONE");
  writer_thread.join();

  if (!written.empty()) std::cout << "Wrote:\n";
  for (auto [filename, size] : written) {
    std::cout << filename << " " << size << "\n";
  }

  auto [bytes_dropped, events_dropped] = n_dropped;
  if (events_dropped != 0) {
    std::cout << "Dropped " << (static_cast<double>(events_dropped) / static_cast<double>(std::get<1>(n_received)) * 100.)
              << "% of events\n";
  }

  return error ? 1 : 0;
}
