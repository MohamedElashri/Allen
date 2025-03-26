/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"
#include "SingleLayerFCNN.cuh"
// Common
#include "States.cuh"

// Local
#include "DownstreamV2Structs.cuh"

namespace downstream_v2_final_fits {

  using GhostKiller = Allen::MVAModels::SingleLayerFCNN<13, 64>;
  // using LegacyGhostKiller = Allen::MVAModels::SingleLayerFCNN<11, 32>;

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // SciFi input
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;

    // Inputs
    DEVICE_INPUT(dev_fitted_downstream_compact_track_offsets_t, unsigned) dev_fitted_downstream_compact_track_offsets;
    HOST_INPUT(host_number_of_selected_downstream_compact_tracks_t, unsigned)
    host_number_of_selected_downstream_compact_tracks;
    DEVICE_INPUT(dev_selected_downstream_compact_track_offsets_t, unsigned)
    dev_selected_downstream_compact_track_offsets;
    DEVICE_INPUT(dev_selected_downstream_compact_tracks_t, Downstream::Structs::CompactTrack)
    dev_selected_downstream_compact_tracks;

    // Outputs
    HOST_OUTPUT(host_number_of_final_downstream_compact_tracks_t, unsigned)
    host_number_of_final_downstream_compact_tracks;
    DEVICE_OUTPUT(dev_final_downstream_compact_track_offsets_t, unsigned) dev_final_downstream_compact_track_offsets;
    DEVICE_OUTPUT(dev_final_downstream_compact_tracks_t, Downstream::Structs::CompactTrack)
    dev_final_downstream_compact_tracks;

    DEVICE_OUTPUT(dev_final_downstream_compact_track_ghost_probs_t, float)
    dev_final_downstream_compact_track_ghost_probs;
    DEVICE_OUTPUT(dev_final_downstream_compact_track_states_t, Downstream::Structs::CompactState)
    dev_final_downstream_compact_track_states;
    DEVICE_OUTPUT(dev_final_downstream_compact_track_qops_t, float) dev_final_downstream_compact_track_qops;
  };

  struct downstream_v2_final_fits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_ghost_killing_threshold {this,
                                                      "ghost_killing_threshold",
                                                      0.5,
                                                      "the ghost killing threshold"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    GhostKiller m_downstream_ghost_killer {"downstream_ghost_killer",
                                           "/GhostProbability/Hlt1_DownstreamV2GhostKiller.json"};
  };

  __global__ void downstream_v2_final_fits(
    Parameters,
    float magnet_polarity,
    const GhostKiller::DeviceType*,
    float ghost_killing_threshold);
} // namespace downstream_v2_final_fits