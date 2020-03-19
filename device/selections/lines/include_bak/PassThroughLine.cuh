/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"

namespace PassThrough {
  struct PassThrough_t : public Hlt1::SpecialLine {
    constexpr static auto name {"PassThrough"};

    static __device__ bool function(const uint*) { return true; }
  };
} // namespace PassThrough
