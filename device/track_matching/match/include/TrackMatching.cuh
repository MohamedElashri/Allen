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
#include "NeuralNetwork.cuh"
#include "TrackMatchingConstants.cuh"
#include "AlgorithmTypes.cuh"
#include "UTHitCache.cuh"

namespace track_matching {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;

    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;

    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_t, unsigned) dev_ut_number_of_selected_velo_tracks;
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

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;

    PROPERTY(
      matching_no_ut_ghost_killer_version_t,
      "matching_no_ut_ghost_killer_version",
      "matching_no_ut_ghost_killer_version",
      int)
    matching_no_ut_ghost_killer_version;

    PROPERTY(
      matching_with_ut_ghost_killer_version_t,
      "matching_with_ut_ghost_killer_version",
      "matching_with_ut_ghost_killer_version",
      int)
    matching_with_ut_ghost_killer_version;

    PROPERTY(multiplication_factor_dX_t, "multiplication_factor_dX", "multiplication_factor_dX", float)
    multiplication_factor_dX;
    PROPERTY(multiplication_factor_dY_t, "multiplication_factor_dY", "multiplication_factor_dY", float)
    multiplication_factor_dY;
    PROPERTY(multiplication_factor_dty_t, "multiplication_factor_dty", "multiplication_factor_dty", float)
    multiplication_factor_dty;
    PROPERTY(multiplication_factor_dtx_t, "multiplication_factor_dtx", "multiplication_factor_dtx", float)
    multiplication_factor_dtx;
    PROPERTY(ghost_killer_threshold_t, "ghost_killer_threshold", "ghost_killer_threshold", float)
    ghost_killer_threshold;

    PROPERTY(momentum_parameters_t, "momentum_parameters", "momentum_parameters", std::array<float, 16>)
    momentum_parameters;

    PROPERTY(z_magnet_parameters_t, "z_magnet_parameters", "z_magnet_parameters", std::array<float, 5>)
    z_magnet_parameters;

    PROPERTY(
      ut_x_loose_tolerance_parameters_t,
      "ut_x_loose_tolerance_parameters",
      "ut_x_loose_tolerance_parameters",
      std::array<float, 4 * 3>)
    ut_x_loose_tolerance_parameters;

    PROPERTY(
      ut_x_tight_tolerance_parameters_t,
      "ut_x_tight_tolerance_parameters",
      "ut_x_tight_tolerance_parameters",
      std::array<float, 4 * 3>)
    ut_x_tight_tolerance_parameters;

    PROPERTY(ut_y_tolerance_parameters_t, "ut_y_tolerance_parameters", "ut_y_tolerance_parameters", float)
    ut_y_tolerance_parameters;

    PROPERTY(min_num_ut_hits_t, "min_num_ut_hits", "min_num_ut_hits", unsigned) min_num_ut_hits;

    PROPERTY(force_skip_ut_t, "force_skip_ut", "force_skip_ut", bool) force_skip_ut;
    PROPERTY(force_no_ut_nn_t, "force_no_ut_nn", "force_no_ut_nn", bool) force_no_ut_nn;
  };

#if defined(TARGET_DEVICE_CUDA)
#if __CUDA_ARCH__ >= 800 // Ampere (A5000)
                         // for 56 registers/thread: 1280=36warps, 1472=32warps, 1664=28warps, 1984=24warps
                         // With 90% UT efficiency, there are < 5000 hits per event -> ~1250 hits/layer => 1280
                         // With 99% UT efficiency, scale it 1280 / 0.9 * 0.99 = 1408 => 1472
  __device__ static constexpr unsigned int MaxCacheSize = 1280;
#else // Volta, Turing: for 56 registers/thread: 1024=32warps,
  __device__ static constexpr unsigned int MaxCacheSize = 1024;
#endif
#else // CPU, HIP
  __device__ static constexpr unsigned int MaxCacheSize = 1;
#endif
  using UTHitsCache = UT::SmartHitsCache<MaxCacheSize>;

  template<typename GhostKiller_t>
  __global__ void track_matching_veloSciFi(
    Parameters,
    const float* dev_magnet_polarity,
    const GhostKiller_t* dev_matching_ghost_killer);

  __global__ void track_matching_add_ut_hits(
    Parameters,
    const float* dev_magnet_polarity,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs,
    const UT::Constants::PerLayerInfo* dev_mean_layer_info);

  __global__ void track_matching_filter_bad_ut_segment(Parameters);

  __global__ void track_matching_select_best_ut_segment(Parameters);

  template<typename GhostKiller_t>
  __global__ void track_matching_ghost_killing(Parameters, const GhostKiller_t* dev_matching_ghost_killer);

  __global__ void track_matching_clone_killing(Parameters);

  struct track_matching_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
    Property<matching_no_ut_ghost_killer_version_t> m_matching_no_ut_ghost_killer_version {this, 2};
    Property<matching_with_ut_ghost_killer_version_t> m_matching_with_ut_ghost_killer_version {this, 2};
    Property<multiplication_factor_dX_t> m_multiplication_factor_dX {this, 0.8};
    Property<multiplication_factor_dY_t> m_multiplication_factor_dY {this, 0.2};
    Property<multiplication_factor_dty_t> m_multiplication_factor_dty {this, 937.5};
    Property<multiplication_factor_dtx_t> m_multiplication_factor_dtx {this, 2.};
    Property<ghost_killer_threshold_t> m_ghost_killer_threshold {this, 0.5};

    // Configured in python
    Property<momentum_parameters_t> m_momentum_parameters {this, {}};

    Property<z_magnet_parameters_t> m_z_magnet_parameters {this, {5287.6f, -7.98878f, 317.683f, 0.0119379f, -1418.42f}};

    // 4 parameters for each layer: offset, slope, min, max
    Property<ut_x_loose_tolerance_parameters_t> m_ut_x_loose_tolerance_parameters {this,
                                                                                   {
                                                                                     0.8333f,
                                                                                     3.3333e4,
                                                                                     1.2f,
                                                                                     8.5f, /* Layer 0 */
                                                                                     0.8333f,
                                                                                     3.3333e4,
                                                                                     1.2f,
                                                                                     8.5f, /* Layer 1 */
                                                                                     1.3333f,
                                                                                     3.3333e4,
                                                                                     1.5f,
                                                                                     9.5f /* Layer 2 */
                                                                                   }};
    // 4 parameters for each layer: offset, slope, min, max
    Property<ut_x_tight_tolerance_parameters_t> m_ut_x_tight_tolerance_parameters {this,
                                                                                   {
                                                                                     0.2f,
                                                                                     0.6e4f,
                                                                                     0.5f,
                                                                                     2.0f, /* Layer 0 */
                                                                                     0.4f,
                                                                                     1.2e4f,
                                                                                     1.0f,
                                                                                     4.0f, /* Layer 1 */
                                                                                     0.4f,
                                                                                     1.2e4f,
                                                                                     1.0f,
                                                                                     4.0f /* Layer 2 */
                                                                                   }};
    Property<ut_y_tolerance_parameters_t> m_ut_y_tolerance_parameters {this, 1.f};

    Property<min_num_ut_hits_t> m_min_num_ut_hits {this, 2u};

    Property<force_skip_ut_t> m_force_skip_ut {this, false};
    Property<force_no_ut_nn_t> m_force_no_ut_nn {this, true};
  };

} // namespace track_matching
