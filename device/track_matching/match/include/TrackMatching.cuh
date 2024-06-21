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

    // Hit caching memory - cache UT hits in global memory in case of it doesn't fit the shared memory
    DEVICE_OUTPUT(dev_hit_caching_memory_t, char) dev_hit_caching_memory;
    DEVICE_OUTPUT(dev_hit_caching_counter_t, unsigned) dev_hit_caching_counter;

    DEVICE_OUTPUT(dev_atomics_matched_tracks_t, unsigned) dev_atomics_matched_tracks;
    DEVICE_OUTPUT(dev_matched_tracks_t, SciFi::MatchedTrack) dev_matched_tracks;

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;

    PROPERTY(
      matching_no_ut_ghost_killer_version_t,
      "matching_no_ut_ghost_killer_version",
      "matching_no_ut_ghost_killer_version",
      int)
    matching_no_ut_ghost_killer_version;

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

    PROPERTY(momentum_parameters_t, "momentum_parameters", "momentum_parameters", std::array<float, 9>)
    momentum_parameters;

    PROPERTY(z_magnet_parameters_t, "z_magnet_parameters", "z_magnet_parameters", std::array<float, 5>)
    z_magnet_parameters;

    PROPERTY(
      loose_ut_hit_tolerance_scaling_factor_t,
      "loose_ut_hit_tolerance_scaling_factor",
      "loose_ut_hit_tolerance_scaling_factor",
      std::array<float, 3>)
    loose_ut_hit_tolerance_scaling_factor;

    PROPERTY(
      tight_ut_hit_tolerance_scaling_factor_t,
      "tight_ut_hit_tolerance_scaling_factor",
      "tight_ut_hit_tolerance_scaling_factor",
      std::array<float, 3>)
    tight_ut_hit_tolerance_scaling_factor;

    PROPERTY(
      y_ut_hit_tolerance_scaling_factor_t,
      "y_ut_hit_tolerance_scaling_factor",
      "y_ut_hit_tolerance_scaling_factor",
      std::array<float, 3>)
    y_ut_hit_tolerance_scaling_factor;

    PROPERTY(force_skip_ut_t, "force_skip_ut", "force_skip_ut", bool) force_skip_ut;
  };

  template<bool has_ut, typename GhostKiller_t>
  __global__ void track_matching_veloSciFi(
    Parameters,
    const float* dev_magnet_polarity,
    const GhostKiller_t* dev_matching_ghost_killer);

  __global__ void track_matching_add_ut_hits(
    Parameters,
    const float* dev_magnet_polarity,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs,
    const float* dev_ut_dxDy,
    const float* dev_mean_layer_z);

  __global__ void track_matching_filter_tracks(
    Parameters,
    const Allen::NeuralNetwork::Model::MatchingWithUTGhostKiller* dev_matching_ghost_killer);

  template<bool has_ut>
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
    Property<multiplication_factor_dX_t> m_multiplication_factor_dX {this, 0.8};
    Property<multiplication_factor_dY_t> m_multiplication_factor_dY {this, 0.2};
    Property<multiplication_factor_dty_t> m_multiplication_factor_dty {this, 937.5};
    Property<multiplication_factor_dtx_t> m_multiplication_factor_dtx {this, 2.};
    Property<ghost_killer_threshold_t> m_ghost_killer_threshold {this, 0.5};

    Property<momentum_parameters_t> m_momentum_parameters {this,
                                                           {0.f,
                                                            1.239076e+03f,
                                                            5.650170e+02f,
                                                            -7.683592e+01f,
                                                            6.148917e+02f,
                                                            2.071115e+03f,
                                                            -6.795680e+03f,
                                                            4.577582e+02f,
                                                            1.f}};

    Property<z_magnet_parameters_t> m_z_magnet_parameters {this, {5287.6f, -7.98878f, 317.683f, 0.0119379f, -1418.42f}};

    Property<loose_ut_hit_tolerance_scaling_factor_t> m_loose_ut_hit_tolerance_scaling_factor {this, {1.f, 1.f, 1.f}};

    Property<tight_ut_hit_tolerance_scaling_factor_t> m_tight_ut_hit_tolerance_scaling_factor {this, {1.f, 1.f, 1.f}};

    Property<y_ut_hit_tolerance_scaling_factor_t> m_y_ut_hit_tolerance_scaling_factor {this, {1.f, 0.f, 1.f}};

    Property<force_skip_ut_t> m_force_skip_ut {this, false};
  };

} // namespace track_matching
