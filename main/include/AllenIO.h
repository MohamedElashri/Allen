/*****************************************************************************\
* (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      *
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
