#pragma once

#include "LineInfo.cuh"

namespace PassThrough {
  struct PassThrough_t : public Hlt1::SpecialLine {
    constexpr static auto name {"PassThrough"};

    static __device__ bool function(const char* odin, const uint n_velo_tracks)
    {
      return false;
    }
  };
} // namespace DiMuonSoft
