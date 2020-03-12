#pragma once

#include <zmq/zmq.hpp>

#if !defined(CPPZMQ_VERSION)
namespace zmq {
  // partially satisfies named requirement BitmaskType
  struct send_flags {
    static int const none = 0;
    static int const dontwait = ZMQ_DONTWAIT;
    static int const sndmore = ZMQ_SNDMORE;
  };
} // namespace zmq
#endif
