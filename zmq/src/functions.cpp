#include <limits.h>
#include <unistd.h>

#include <zmq/zmq.hpp>
#include <ZeroMQ/functions.h>

namespace ZMQ {
  size_t stringLength(const char& cs) { return strlen(&cs); }
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
