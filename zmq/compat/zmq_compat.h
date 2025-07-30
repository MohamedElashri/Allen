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
