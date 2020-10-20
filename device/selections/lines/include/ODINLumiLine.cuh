/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"
#include "Event/ODIN.h"

namespace ODINLumi {
  constexpr unsigned eventType = LHCb::ODIN::Lumi;

  struct ODINLumi_t : public Hlt1::SpecialLine {
    constexpr static auto name {"ODINLumi"};
    constexpr static auto scale_factor = 1e-3f;

    static __device__ bool function(const char* odin)
    {
      const unsigned hdr_size(8);
      const uint32_t* odinData = reinterpret_cast<const uint32_t*>(
        odin + hdr_size);
      const uint32_t word2 = odinData[LHCb::ODIN::Data::EventType];
      if (word2 & eventType) return true;

      return false;
    }
  };
} // namespace ODINLumi
