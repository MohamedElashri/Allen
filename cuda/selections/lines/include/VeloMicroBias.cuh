#pragma once

#include "LineInfo.cuh"
#include "odin.hpp"

namespace VeloMicroBias {
  constexpr uint min_velo_tracks=1;

  struct VeloMicroBias_t : public Hlt1::SpecialLine {
    constexpr static auto name {"VeloMicroBias"};
    constexpr static auto scale_factor = 1e-3f;

    static __device__ bool function(const char* /*odin*/, const uint n_velo_tracks)
    {
      return n_velo_tracks>=min_velo_tracks;
    }
  };
} // namespace VeloMicroBias
