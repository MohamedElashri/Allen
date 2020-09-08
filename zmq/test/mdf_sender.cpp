/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <iostream>

#include <fcntl.h>

#include <ZeroMQ/IZeroMQSvc.h>
#include <read_mdf.hpp>
#include <zmq/svc.h>

#include <boost/program_options.hpp>

namespace {
  using namespace std::string_literals;
  namespace po = boost::program_options;
  using namespace zmq;
  using namespace std;
} // namespace

namespace Utils {
  std::string hostname()
  {
    char hname[HOST_NAME_MAX];
    std::string hn;
    if (!gethostname(hname, sizeof(hname))) {
      hn = std::string {hname};
      auto pos = hn.find('.');
      if (pos != std::string::npos) {
        hn = hn.substr(0, pos);
      }
    }
    return hn;
  }
} // namespace Utils

int main(int argc, char* argv[])
{

  string filename;
  size_t n_events;
  int interval;
  std::string receiver_connection;

  // Declare the supported options.
  po::options_description desc("Allowed options");
  desc.add_options()("help,h", "produce help message")(
    "receiver", po::value<std::string>(&receiver_connection), "receiver connection")(
    "mdf_file", po::value<std::string>(&filename), "MDF file")(
    "events", po::value<size_t>(&n_events), "number of events")(
    "interval,i", po::value<int>(&interval)->default_value(500), "interval between sending of events");

  po::positional_options_description p;
  p.add("receiver", 1);
  p.add("mdf_file", 1);
  p.add("events", 1);

  po::variables_map vm;
  po::store(po::command_line_parser(argc, argv).options(desc).positional(p).run(), vm);
  po::notify(vm);

  if (vm.count("help")) {
    std::cout << desc << "\n";
    return 1;
  }

  auto zmqSvc = makeZmqSvc();

  // Some storage for reading the events into
  LHCb::MDFHeader header;
  vector<char> read_buffer(1024 * 1024, '\0');
  vector<char> decompression_buffer(1024 * 1024, '\0');

  bool eof = false, error = false;

  gsl::span<const char> bank_span;

  auto input = MDF::open(filename.c_str(), O_RDONLY);
  if (input.good) {
    cout << "Opened " << filename << "\n";
  }
  else {
    cerr << "Failed to open file " << filename << " " << strerror(errno) << "\n";
    return -1;
  }

  auto const pos = receiver_connection.rfind(":");
  auto const receiver = receiver_connection.substr(0, pos);

  auto request = zmqSvc->socket(zmq::REQ);
  zmq::setsockopt(request, zmq::LINGER, 0);
  request.connect(receiver_connection.c_str());
  auto id = "Test_"s + Utils::hostname() + "_" + std::to_string(::getpid());
  zmqSvc->send(request, "PORT", send_flags::sndmore);
  zmqSvc->send(request, id);

  std::optional<zmq::socket_t> data_socket;

  // Wait for reply for a second
  {
    zmq::pollitem_t items[] = {{request, 0, zmq::POLLIN, 0}};
    zmq::poll(&items[0], 1, 500);
    if (items[0].revents & zmq::POLLIN) {
      auto port = zmqSvc->receive<std::string>(request);
      std::string connection = receiver + ":" + port;
      data_socket = zmqSvc->socket(zmq::PAIR);
      zmq::setsockopt(*data_socket, zmq::LINGER, 0);
      data_socket->connect(connection.c_str());
      cout << "Connected MDF output socket to " << connection << "\n";
    }
    else {
      exit(1);
    }
  }

  zmq::pollitem_t items[] = {{*data_socket, 0, zmq::POLLIN, 0}};

  size_t i_event = 0;
  while (!eof && i_event++ < n_events) {

    // Check if there are messages
    auto n = zmq::poll(&items[0], 1, interval);

    // Handle
    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc->receive<std::string>(*data_socket);
      if (msg == "RECEIVER_STOP") {
        cout << "MDF receiver is exiting\n";
        zmqSvc->send(*data_socket, "OK");
        break;
      }
      else {
        cout << "Received unknown message from output receiver: " << msg << "\n";
      }
    }

    if (n == 0) {
      std::tie(eof, error, bank_span) = MDF::read_event(input, header, read_buffer, decompression_buffer, true);
      if (eof || error) {
        break;
      }

      // Send event. Use the fact that the reading first creates a
      // status bank that contains the header as payload. By starting
      // there, the whole event can be read in one go.
      auto const* status_bank = reinterpret_cast<LHCb::RawBank const*>(bank_span.data());
      auto const event_size = bank_span.size() - status_bank->hdrSize();
      zmq::message_t msg(event_size);
      memcpy(msg.data(), status_bank->data(), event_size);
      zmqSvc->send(*data_socket, "EVENT", send_flags::sndmore);
      zmqSvc->send(*data_socket, msg);
    }
  }

  {
    zmqSvc->send(request, "CLIENT_EXIT", send_flags::sndmore);
    zmqSvc->send(request, id);
    zmq::pollitem_t items[] = {{request, 0, zmq::POLLIN, 0}};
    zmq::poll(&items[0], 1, 500);
    if (items[0].revents & zmq::POLLIN) {
      zmqSvc->receive<std::string>(request);
    }
  }
}
