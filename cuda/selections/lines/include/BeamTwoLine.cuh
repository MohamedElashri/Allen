#pragma once

#include "LineInfo.cuh"
#include "Event/ODIN.h"

namespace BeamTwo {
  constexpr uint bxType = LHCb::ODIN::Beam2;

  struct BeamTwo_t : public Hlt1::SpecialLine {
    constexpr static auto name {"BeamTwo"};
    constexpr static auto scale_factor = 1e-3f;

    static __device__ bool function(const char* odin)
    {
      const uint hdr_size(8);
      const uint32_t* odinData = reinterpret_cast<const uint32_t*>(
        odin + hdr_size);
      const uint32_t word8 = odinData[LHCb::ODIN::Data::Word8];
      const uint bxt = (word8 & LHCb::ODIN::BXTypeMask) >> LHCb::ODIN::BXTypeBits;
      if (bxt == bxType) return true;

      return false;
    }
  };
} // namespace BeamTwo
