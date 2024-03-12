/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "VeloConsolidated.cuh"

namespace FillMaterialInteractionCandidates {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_total_interaction_seeds_t, unsigned) host_number_of_total_interaction_seeds;

    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_track_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_filtered_velo_track_idx_t, unsigned) dev_filtered_velo_track_idx;
    DEVICE_INPUT(dev_number_of_filtered_tracks_t, unsigned) dev_number_of_filtered_tracks;
    DEVICE_INPUT(dev_interaction_seeds_offsets_t, unsigned) dev_interaction_seeds_offsets;

    DEVICE_OUTPUT(dev_interaction_seeds_t, float3) dev_interaction_seeds;

    PROPERTY(
      max_doca_for_close_track_pairs_t,
      "max_doca_for_close_track_pairs",
      "doca to define close track pairs",
      float)
    max_doca_for_close_track_pairs;

    PROPERTY(block_dim_t, "block_dim", "block dimension", DeviceDimensions) block_dim;
  };

  __global__ void fill_materialinteraction_candidates(Parameters);

  struct fill_materialinteraction_candidates_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<max_doca_for_close_track_pairs_t> m_max_doca_for_close_track_pairs {this, 0.15f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };

} // namespace FillMaterialInteractionCandidates
