#pragma once

#include "Handler.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"

#include "odin.hpp"

namespace postscale {
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

__global__ void run_postscale(
  char* dev_odin_raw_input,
  uint* dev_odin_raw_input_offsets,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  bool* dev_one_track_results,
  bool* dev_two_track_results,
  bool* dev_single_muon_results,
  bool* dev_disp_dimuon_results,
  bool* dev_high_mass_dimuon_results,
  bool* dev_dimuon_soft_results);

namespace Configuration {
  namespace run_postscale_t {
    extern __constant__ float factor_one_track;
    extern __constant__ float factor_single_muon;
    extern __constant__ float factor_two_tracks;
    extern __constant__ float factor_disp_dimuon;
    extern __constant__ float factor_high_mass_dimuon;
    extern __constant__ float factor_dimuon_soft;
  } // namespace run_postscale_t
} // namespace Configuration

ALGORITHM(
  run_postscale,
  run_postscale_t,
  ARGUMENTS(
    dev_odin_raw_input,
    dev_odin_raw_input_offsets,
    dev_atomics_scifi,
    dev_sv_offsets,
    dev_one_track_results,
    dev_two_track_results,
    dev_single_muon_results,
    dev_disp_dimuon_results,
    dev_high_mass_dimuon_results,
    dev_dimuon_soft_results),
  Property<float> factor_one_track {this,
                    "factor_one_track",
                    Configuration::run_postscale_t::factor_one_track,
                    1.,
                    "postscale for one-track line"};
  Property<float> factor_single_muon {this,
                    "factor_single_muon",
                    Configuration::run_postscale_t::factor_single_muon,
                    1.,
                    "postscale for single-muon line"};
  Property<float> factor_two_tracks {this,
                    "factor_two_tracks",
                    Configuration::run_postscale_t::factor_two_tracks,
                    1.,
                    "postscale for two-track line"};
  Property<float> factor_disp_dimuon {this,
                    "factor_disp_dimuon",
                    Configuration::run_postscale_t::factor_disp_dimuon,
                    1.,
                    "postscale for displaced-dimuon line"};
  Property<float> factor_high_mass_dimuon {this,
                    "factor_high_mass_dimuon",
                    Configuration::run_postscale_t::factor_high_mass_dimuon,
                    1.,
                    "postscale for high-mass-dimuon line"};
  Property<float> factor_dimuon_soft {this,
                    "factor_dimuon_soft",
                    Configuration::run_postscale_t::factor_dimuon_soft,
                    1.,
                    "postscale for soft-dimuon line"};
  )
