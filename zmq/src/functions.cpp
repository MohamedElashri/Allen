/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
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
