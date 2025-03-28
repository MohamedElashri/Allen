/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "VeloEventModel.cuh"
#include "VeloDefinitions.cuh"
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "SingleLayerFCNN.cuh"
#include "TrackMatchingConstants.cuh"
#include "AlgorithmTypes.cuh"
#include "UTHitCache.cuh"
#include "AllenMonitoring.h"
#include "LongTrackMomentumEvaluation.cuh"

namespace track_matching {

  constexpr unsigned MaxNumIteration = 2;

  using MatchingGhostKiller = Allen::MVAModels::SingleLayerFCNN<7, 32>;
  using MatchingNoUTV2GhostKiller = Allen::MVAModels::SingleLayerFCNN<8, 32>;
  using MatchingWithUTGhostKiller = Allen::MVAModels::SingleLayerFCNN<11, 32>;
  using MatchingWithUTV2GhostKiller = Allen::MVAModels::SingleLayerFCNN<10, 32>;

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;

    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;

    DEVICE_INPUT(dev_ut_selected_velo_tracks_offsets_t, unsigned) dev_ut_selected_velo_tracks_offsets;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;

    DEVICE_OUTPUT(dev_atomics_matched_tracks_t, unsigned) dev_atomics_matched_tracks;
    DEVICE_OUTPUT(dev_matched_tracks_t, SciFi::MatchedTrack) dev_matched_tracks;

    DEVICE_OUTPUT(dev_offsets_matched_tracks_t, unsigned) dev_offsets_matched_tracks;
    HOST_OUTPUT(host_number_of_reconstructed_matched_tracks_t, unsigned)
    host_number_of_reconstructed_matched_tracks;
  };

#if defined(TARGET_DEVICE_CUDA)
#if __CUDA_ARCH__ >= 800 // Ampere (A5000)
                         // for 56 registers/thread: 1280=36warps, 1472=32warps, 1664=28warps, 1984=24warps
                         // With 90% UT efficiency, there are < 5000 hits per event -> ~1250 hits/layer => 1280
                         // With 99% UT efficiency, scale it 1280 / 0.9 * 0.99 = 1408 => 1472
  __device__ static constexpr unsigned int MaxCacheSize = 1276;
#else // Volta, Turing: for 56 registers/thread: 1024=32warps,
  __device__ static constexpr unsigned int MaxCacheSize = 1020;
#endif
#else // CPU, HIP
  __device__ static constexpr unsigned int MaxCacheSize = 1;
#endif
  using UTHitsCache = UTHitCache::FullHitCache_8Bytes<MaxCacheSize>;

  template<typename GhostKiller_t>
  __global__ void track_matching_veloSciFi(
    Parameters,
    const float* dev_magnet_polarity,
    const GhostKiller_t* dev_matching_ghost_killer,
    const std::array<float, 16>,
    const std::array<float, 5>,
    const float,
    const float,
    const float,
    const float,
    const float,
    Allen::Monitoring::Counter<>::DeviceType);

  __global__ void track_matching_add_ut_hits(
    Parameters,
    const float* dev_magnet_polarity,
    const std::array<float, 4 * 3> ut_x_loose_tolerance_parameters,
    const std::array<float, 4 * 3> ut_x_tight_tolerance_parameters,
    const float ut_y_tolerance_parameters,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    Allen::Monitoring::Counter<>::DeviceType);

  __global__ void track_matching_filter_bad_ut_segment(Parameters, const unsigned min_num_ut_hits);

  __global__ void track_matching_select_best_ut_segment(Parameters);

  template<typename GhostKiller_t>
  __global__ void track_matching_ghost_killing(
    Parameters,
    const std::array<float, 5>,
    const float,
    const float,
    const float,
    const float,
    const float,
    const GhostKiller_t* dev_matching_ghost_killer);

  __global__ void track_matching_clone_killing(Parameters);

  struct track_matching_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Monitoring::Counter<> m_n_overflow_track_matching {this, "n_overflow_track_matching"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<int> m_matching_no_ut_ghost_killer_version {this,
                                                                "matching_no_ut_ghost_killer_version",
                                                                2,
                                                                "matching_no_ut_ghost_killer_version"};
    Allen::Property<int> m_matching_with_ut_ghost_killer_version {this,
                                                                  "matching_with_ut_ghost_killer_version",
                                                                  2,
                                                                  "matching_with_ut_ghost_killer_version"};
    Allen::Property<float> m_multiplication_factor_dX {this,
                                                       "multiplication_factor_dX",
                                                       0.8,
                                                       "multiplication_factor_dX"};
    Allen::Property<float> m_multiplication_factor_dY {this,
                                                       "multiplication_factor_dY",
                                                       0.2,
                                                       "multiplication_factor_dY"};
    Allen::Property<float> m_multiplication_factor_dty {this,
                                                        "multiplication_factor_dty",
                                                        937.5,
                                                        "multiplication_factor_dty"};
    Allen::Property<float> m_multiplication_factor_dtx {this,
                                                        "multiplication_factor_dtx",
                                                        2.,
                                                        "multiplication_factor_dtx"};
    Allen::Property<float> m_ghost_killer_threshold {this, "ghost_killer_threshold", 0.5, "ghost_killer_threshold"};

    // Configured in python
    Allen::Property<std::array<float, 16>> m_momentum_parameters {this,
                                                                  "momentum_parameters",
                                                                  {},
                                                                  "momentum_parameters"};

    Allen::Property<std::array<float, 5>> m_z_magnet_parameters {this,
                                                                 "z_magnet_parameters",
                                                                 {5287.6f, -7.98878f, 317.683f, 0.0119379f, -1418.42f},
                                                                 "z_magnet_parameters"};

    // 4 parameters for each layer: offset, slope, min, max
    Allen::Property<std::array<float, 4 * 3>> m_ut_x_loose_tolerance_parameters {this,
                                                                                 "ut_x_loose_tolerance_parameters",
                                                                                 {0.8333f,
                                                                                  3.3333e4,
                                                                                  1.2f,
                                                                                  8.5f,
                                                                                  /* Layer 0 */ 0.8333f,
                                                                                  3.3333e4,
                                                                                  1.2f,
                                                                                  8.5f,
                                                                                  /* Layer 1 */ 1.3333f,
                                                                                  3.3333e4,
                                                                                  1.5f,
                                                                                  9.5f /* Layer 2 */},
                                                                                 "ut_x_loose_tolerance_parameters"};
    // 4 parameters for each layer: offset, slope, min, max
    Allen::Property<std::array<float, 4 * 3>> m_ut_x_tight_tolerance_parameters {this,
                                                                                 "ut_x_tight_tolerance_parameters",
                                                                                 {0.2f,
                                                                                  0.6e4f,
                                                                                  0.5f,
                                                                                  2.0f,
                                                                                  /* Layer 0 */ 0.4f,
                                                                                  1.2e4f,
                                                                                  1.0f,
                                                                                  4.0f,
                                                                                  /* Layer 1 */ 0.4f,
                                                                                  1.2e4f,
                                                                                  1.0f,
                                                                                  4.0f /* Layer 2 */},
                                                                                 "ut_x_tight_tolerance_parameters"};
    Allen::Property<float> m_ut_y_tolerance_parameters {this,
                                                        "ut_y_tolerance_parameters",
                                                        1.f,
                                                        "ut_y_tolerance_parameters"};

    Allen::Property<unsigned> m_min_num_ut_hits {this, "min_num_ut_hits", 2u, "min_num_ut_hits"};

    Allen::Property<bool> m_force_skip_ut {this, "force_skip_ut", false, "force_skip_ut"};
    Allen::Property<bool> m_force_no_ut_nn {this, "force_no_ut_nn", true, "force_no_ut_nn"};

    MatchingGhostKiller matching_ghost_killer {"matching_ghost_killer",
                                               "/GhostProbability/Hlt1_LongGhostKiller_Matching.json"};
    MatchingWithUTGhostKiller matching_with_ut_ghost_killer {
      "matching_with_ut_ghost_killer",
      "/GhostProbability/Hlt1_LongGhostKiller_MatchingWithUT.json"};
    MatchingNoUTV2GhostKiller matching_no_ut_v2_ghost_killer {
      "matching_no_ut_v2_ghost_killer",
      "/GhostProbability/Hlt1_LongGhostKiller_MatchingNoUT_V2.json"};
    MatchingWithUTV2GhostKiller matching_with_ut_v2_ghost_killer {
      "matching_with_ut_v2_ghost_killer",
      "/GhostProbability/Hlt1_LongGhostKiller_MatchingWithUT_V2.json"};
  };

} // namespace track_matching
