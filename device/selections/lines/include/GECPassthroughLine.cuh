/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"
#include "Event/ODIN.h"

namespace GECPassthrough {

  // Line for checking if an event passes the GEC.
  struct GECPassthrough_t : public Hlt1::VeloLine {
    constexpr static auto name {"GECPassthrough"};
    static __device__ bool function(const unsigned) {
      return true;
    }
  };
  
} // namespace GECPassthrough