/*****************************************************************************\
* (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <cstdio>
#include <functional>

namespace Allen {
  struct IO {
    bool good = false;
    std::function<ssize_t(char*, size_t)> read;
    std::function<ssize_t(char const*, size_t)> write;
    std::function<void(void)> close;
  };
} // namespace Allen
