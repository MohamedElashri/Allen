/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"

namespace ErrorEvent {
  struct ErrorEvent_t : public Hlt1::SpecialLine {
    constexpr static auto name {"ErrorEvent"};

    static __device__ bool function(const char*) { return false; }
  };
} // namespace ErrorEvent
