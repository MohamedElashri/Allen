/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"
#include "Event/ODIN.h"

namespace NoBeams {
  constexpr unsigned bxType = LHCb::ODIN::NoBeam;

  struct NoBeams_t : public Hlt1::SpecialLine {
    constexpr static auto name {"NoBeams"};
    constexpr static auto scale_factor = 0.5f;

    static __device__ bool function(const uint* odin)
    {
      const uint32_t word8 = odin[LHCb::ODIN::Data::Word8];
      const unsigned bxt = (word8 & LHCb::ODIN::BXTypeMask) >> LHCb::ODIN::BXTypeBits;
      return bxt == bxType;
    }
  };
} // namespace NoBeams
