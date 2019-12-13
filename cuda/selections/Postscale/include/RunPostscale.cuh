#pragma once

#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"

#include "odin.hpp"

namespace postscale {
  const float factor_one_track = 1.;
  const float factor_single_muon = 1.;
  const float factor_two_tracks = 1.;
  const float factor_disp_dimuon = 1.;
  const float factor_high_mass_dimuon = 1.;
  const float factor_dimuon_soft = 1.;

  __device__ uint32_t mix( uint32_t state );
  __device__ uint32_t mix32( uint32_t state, uint32_t extra );
  __device__ uint32_t mix64( uint32_t state, uint64_t extra );
};

struct DeterministicPostscaler {
  __device__ DeterministicPostscaler(uint initial, float frac)
    : initial_value( initial ),
      scale_factor( frac ),
      accept_threshold(frac >= 1. ? std::numeric_limits<uint32_t>::max()
                                  : uint32_t( frac * std::numeric_limits<uint32_t>::max() ) )
        {}

  __device__ void operator()(const int n_candidates, bool* results, const LHCb::ODIN& odin);

  uint32_t initial_value{0};
  uint32_t accept_threshold{std::numeric_limits<uint32_t>::max()};
  float scale_factor{1.};
};

__global__ void run_postscale(
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  bool* dev_one_track_results,
  bool* dev_two_track_results,
  bool* dev_single_muon_results,
  bool* dev_disp_dimuon_results,
  bool* dev_high_mass_dimuon_results,
  bool* dev_dimuon_soft_results);

ALGORITHM(
  run_postscale,
  run_postscale_t,
  ARGUMENTS(
    dev_atomics_scifi,
    dev_sv_offsets,
    dev_one_track_results,
    dev_two_track_results,
    dev_single_muon_results,
    dev_disp_dimuon_results,
    dev_high_mass_dimuon_results,
    dev_dimuon_soft_results))
