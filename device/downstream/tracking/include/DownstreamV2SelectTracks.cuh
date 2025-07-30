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

// Common
#include "States.cuh"

// Local
#include "DownstreamV2Structs.cuh"

namespace downstream_v2_select_tracks {

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // SciFi
    // HOST_INPUT(host_total_number_of_scifi_tracks_t, unsigned) host_total_number_of_scifi_tracks;
    DEVICE_INPUT(dev_offsets_seeding_tracks_t, unsigned) dev_offsets_seeding_tracks;

    // UT input
    // HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // From tracking
    DEVICE_INPUT(dev_downstream_compact_track_offsets_t, unsigned) dev_downstream_compact_track_offsets;
    HOST_INPUT(host_number_of_fitted_downstream_compact_tracks_t, unsigned)
    host_number_of_fitted_downstream_compact_tracks;
    DEVICE_INPUT(dev_fitted_downstream_compact_track_offsets_t, unsigned) dev_fitted_downstream_compact_track_offsets;
    DEVICE_INPUT(dev_fitted_downstream_compact_tracks_t, Downstream::Structs::CompactTrack)
    dev_fitted_downstream_compact_tracks;
    DEVICE_INPUT(dev_fitted_downstream_compact_track_scores_t, float) dev_fitted_downstream_compact_track_scores;

    // Buffer
    // DEVICE_OUTPUT(dev_ut_hits_buffer_t, float) dev_ut_hits_buffer;
    // DEVICE_OUTPUT(dev_scifi_tracks_buffer_t, float) dev_scifi_tracks_buffer;
    DEVICE_OUTPUT(dev_downstream_compact_track_selections_t, uint8_t) dev_downstream_compact_track_selections;

    // Output`
    HOST_OUTPUT(host_number_of_selected_downstream_compact_tracks_t, unsigned)
    host_number_of_selected_downstream_compact_tracks;
    DEVICE_OUTPUT(dev_selected_downstream_compact_track_offsets_t, unsigned)
    dev_selected_downstream_compact_track_offsets;
    DEVICE_OUTPUT(dev_selected_downstream_compact_tracks_t, Downstream::Structs::CompactTrack)
    dev_selected_downstream_compact_tracks;
  };

  struct downstream_v2_select_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<float> m_max_score {this, "max_score", 1.f, "Max score"};
    Allen::Property<unsigned> m_num_independent_hits {this, "num_independent_hits", 2, "Number of independent UT hits"};
    Allen::Property<bool> m_clone_killing {this, "clone_killing", true, "enable clone killing"};
  };

  __global__ void downstream_v2_clone_killing(Parameters, unsigned num_independent_hits, bool clone_killing);

} // namespace downstream_v2_select_tracks