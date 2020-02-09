#pragma once

#include "LineInfo.cuh"
#include "Event/ODIN.h"

namespace ODINNoBias {
  constexpr uint eventType = LHCb::ODIN::NoBias;

  struct ODINNoBias_t : public Hlt1::SpecialLine {
    constexpr static auto name {"ODINNoBias"};
    constexpr static auto scale_factor = 1e-3f;

    static __device__ bool function(const char* odin, const uint n_velo_tracks)
    {
      const uint hdr_size(8);
      const uint32_t* odinData = reinterpret_cast<const uint32_t*>(
        odin + hdr_size);
      const uint32_t word2 = odinData[LHCb::ODIN::Data::EventType];
      if (word2 & eventType) return true;

      return false;
    }
  };
} // namespace ODINNoBias
