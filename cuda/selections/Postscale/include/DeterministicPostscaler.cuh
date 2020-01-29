#pragma once

#include "DeviceAlgorithm.cuh"

namespace postscaler {
  __device__ uint32_t mix( uint32_t state );
  __device__ uint32_t mix32( uint32_t state, uint32_t extra );
  __device__ uint32_t mix64( uint32_t state, uint32_t extra_hi, uint32_t extra_lo );
};

struct DeterministicPostscaler {
  __device__ DeterministicPostscaler(uint initial, float frac)
    : initial_value( initial ),
      scale_factor( frac ),
      accept_threshold(frac >= 1. ? std::numeric_limits<uint32_t>::max()
                                  : uint32_t( frac * std::numeric_limits<uint32_t>::max() ) )
        {}

  __device__ void operator()(
    const int n_candidates,
    bool* results,
    const uint32_t run_number,
    const uint32_t evt_number_hi,
    const uint32_t evt_number_lo,
    const uint32_t gps_time_hi,
    const uint32_t gps_time_lo);

  uint32_t initial_value{0};
  uint32_t accept_threshold{std::numeric_limits<uint32_t>::max()};
  float scale_factor{1.};
};
