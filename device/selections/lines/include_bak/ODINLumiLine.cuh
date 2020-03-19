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
    constexpr static auto scale_factor = 0.5f;

    static __device__ bool function(const uint* odin)
    {
      const uint32_t word2 = odin[LHCb::ODIN::Data::EventType];
      return word2 & eventType;
    }
  };
} // namespace ODINLumi
