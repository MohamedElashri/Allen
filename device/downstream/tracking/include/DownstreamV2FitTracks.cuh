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

namespace downstream_v2_fit_tracks {

  using CloneKiller = Allen::MVAModels::SingleLayerFCNN<13, 32>;

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

    // From tracking
    HOST_INPUT(host_number_of_downstream_compact_tracks_t, unsigned) host_number_of_downstream_compact_tracks;
    DEVICE_INPUT(dev_downstream_compact_track_offsets_t, unsigned) dev_downstream_compact_track_offsets;
    DEVICE_INPUT(dev_downstream_compact_tracks_t, Downstream::Structs::CompactTrack) dev_downstream_compact_tracks;

    // Outputs
    HOST_OUTPUT(host_number_of_fitted_downstream_compact_tracks_t, unsigned)
    host_number_of_fitted_downstream_compact_tracks;
    DEVICE_OUTPUT(dev_fitted_downstream_compact_track_offsets_t, unsigned) dev_fitted_downstream_compact_track_offsets;
    DEVICE_OUTPUT(dev_fitted_downstream_compact_tracks_t, Downstream::Structs::CompactTrack)
    dev_fitted_downstream_compact_tracks;
    DEVICE_OUTPUT(dev_fitted_downstream_compact_track_scores_t, float) dev_fitted_downstream_compact_track_scores;
  };

  struct downstream_v2_fit_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_clone_killing_threshold {this,
                                                      "clone_killing_threshold",
                                                      1.0,
                                                      "the clone killing threshold"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    CloneKiller m_downstream_clone_killer {"downstream_clone_killer",
                                           "/GhostProbability/Hlt1_DownstreamV2CloneKiller.json"};
  };

  __global__ void downstream_v2_fit_tracks(Parameters, const CloneKiller::DeviceType*, float clone_killing_threshold);
} // namespace downstream_v2_fit_tracks