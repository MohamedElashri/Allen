/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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

namespace track_matching_veloSciFi {
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

    DEVICE_OUTPUT(dev_atomics_matched_tracks_t, unsigned) dev_atomics_matched_tracks;
    DEVICE_OUTPUT(dev_matched_tracks_t, SciFi::MatchedTrack) dev_matched_tracks;

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;

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
  };
  __global__ void track_matching_veloSciFi(
    Parameters,
    const float* dev_magnet_polarity,
    const TrackMatchingConsts::MagnetParametrization* dev_magnet_parametrization,
    const Allen::NeuralNetwork::Model::MatchingGhostKiller* dev_matching_ghost_killer);

  struct track_matching_veloSciFi_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
    Property<multiplication_factor_dX_t> m_multiplication_factor_dX {this, 0.8};
    Property<multiplication_factor_dY_t> m_multiplication_factor_dY {this, 0.2};
    Property<multiplication_factor_dty_t> m_multiplication_factor_dty {this, 937.5};
    Property<multiplication_factor_dtx_t> m_multiplication_factor_dtx {this, 2.};
    Property<ghost_killer_threshold_t> m_ghost_killer_threshold {this, 0.5};
  };

} // namespace track_matching_veloSciFi
