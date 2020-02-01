#include <zmq.hpp>
#include <limits.h>
#include <unistd.h>
#include <functions.h>

namespace ZMQ {
  size_t stringLength(const char& cs) { return strlen(&cs); }

  std::string connection(const size_t id, std::string suffix)
  {
    auto con = std::string {"inproc://control_"} + std::to_string(id);
    if (!suffix.empty()) {
      con += "_" + suffix;
    }
    return con;
  }
} // namespace ZMQ

namespace zmq {

  void setsockopt(zmq::socket_t& socket, const zmq::SocketOptions opt, const int value)
  {
    socket.setsockopt(opt, &value, sizeof(int));
  }

  // special case for const char and string
  void setsockopt(zmq::socket_t& socket, const zmq::SocketOptions opt, const std::string value)
  {
    socket.setsockopt(opt, value.c_str(), value.length());
  }

  // special case for const char and string
  void setsockopt(zmq::socket_t& socket, const zmq::SocketOptions opt, const char* value)
  {
    socket.setsockopt(opt, value, strlen(value));
  }

} // namespace zmq

namespace Utils {
  std::string hostname() {
    char hname[HOST_NAME_MAX];
    std::string hn;
    if (!gethostname(hname, sizeof(hname))) {
      hn = std::string{hname};
      auto pos = hn.find('.');
      if (pos != std::string::npos) {
        hn = hn.substr(0, pos);
      }
    }
    return hn;
  }
}
