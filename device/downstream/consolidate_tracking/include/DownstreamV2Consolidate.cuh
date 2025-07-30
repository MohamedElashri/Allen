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

// Allen
#include "AlgorithmTypes.cuh"
#include "AllenMonitoring.h"

// Event types
#include "ParticleTypes.cuh"
#include "States.cuh"

// Downstream
#include "DownstreamV2Structs.cuh"

namespace downstream_v2_consolidate {
  struct Parameters {
    // Basic input
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Scifi input
    DEVICE_INPUT(dev_scifi_track_view_t, Allen::Views::SciFi::Consolidated::Track) dev_scifi_track_view;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;

    // Downstream offsets
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;
    DEVICE_INPUT(dev_downstream_track_offsets_t, unsigned) dev_downstream_track_offsets;
    HOST_INPUT(host_number_of_downstream_hits_t, unsigned) host_number_of_downstream_hits;
    DEVICE_INPUT(dev_downstream_track_hit_offsets_t, unsigned) dev_downstream_track_hit_offsets;

    // Downstream inputs
    DEVICE_INPUT(dev_downstream_compact_track_input_offsets_t, unsigned) dev_downstream_compact_track_input_offsets;
    DEVICE_INPUT(dev_downstream_compact_tracks_t, Downstream::Structs::CompactTrack) dev_downstream_compact_tracks;
    DEVICE_INPUT(dev_downstream_compact_track_states_t, Downstream::Structs::CompactState)
    dev_downstream_compact_track_states;
    DEVICE_INPUT(dev_downstream_compact_track_scores_t, float) dev_downstream_compact_track_scores;
    DEVICE_INPUT(dev_downstream_compact_track_qops_t, float) dev_downstream_compact_track_qops;

    // Output
    DEVICE_OUTPUT(dev_downstream_track_states_t, char) dev_downstream_track_states;
    DEVICE_OUTPUT(dev_downstream_track_hits_t, char) dev_downstream_track_hits;
    DEVICE_OUTPUT(dev_downstream_track_qops_t, float) dev_downstream_track_qops;
    DEVICE_OUTPUT(dev_downstream_track_ghost_probability_t, float) dev_downstream_track_ghost_probability;
    DEVICE_OUTPUT(dev_downstream_track_scifi_indices_t, unsigned) dev_downstream_track_scifi_indices;
    DEVICE_OUTPUT(dev_downstream_track_scifi_states_t, MiniState) dev_downstream_track_scifi_states;
    //
    // Views outputs : UT tracks
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_hits_view_t,
      DEPENDENCIES(dev_downstream_track_hits_t),
      Allen::Views::UT::Consolidated::Hits)
    dev_downstream_hits_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_ut_track_view_t,
      DEPENDENCIES(dev_downstream_hits_view_t),
      Allen::Views::UT::Consolidated::Track)
    dev_downstream_ut_track_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_ut_tracks_view_t,
      DEPENDENCIES(dev_downstream_ut_track_view_t),
      Allen::Views::UT::Consolidated::Tracks)
    dev_downstream_ut_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_ut_tracks_view_t,
      DEPENDENCIES(dev_downstream_ut_tracks_view_t),
      Allen::Views::UT::Consolidated::MultiEventTracks)
    dev_multi_event_downstream_ut_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_ut_tracks_view_ptr_t,
      DEPENDENCIES(dev_multi_event_downstream_ut_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_downstream_ut_tracks_view_ptr;

    //
    // Views outputs : states
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_track_states_view_t,
      DEPENDENCIES(dev_downstream_track_states_t),
      Allen::Views::Physics::KalmanStates)
    dev_downstream_track_states_view;

    //
    // Views outputs : Downstream tracks
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_track_view_t,
      DEPENDENCIES(
        dev_downstream_ut_tracks_view_t,
        dev_scifi_track_view_t,
        dev_downstream_track_qops_t,
        dev_downstream_track_ghost_probability_t),
      Allen::Views::Physics::DownstreamTrack)
    dev_downstream_track_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_tracks_view_t,
      DEPENDENCIES(dev_downstream_track_view_t),
      Allen::Views::Physics::DownstreamTracks)
    dev_downstream_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_tracks_view_t,
      DEPENDENCIES(dev_downstream_tracks_view_t),
      Allen::Views::Physics::MultiEventDownstreamTracks)
    dev_multi_event_downstream_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_tracks_view_ptr_t,
      DEPENDENCIES(dev_multi_event_downstream_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_downstream_tracks_view_ptr;
  };

  __global__ void downstream_v2_consolidate_tracks(Parameters);

  __global__ void downstream_v2_create_track_views(Parameters);

  __global__ void downstream_v2_track_monitoring(
    Parameters,
    Allen::Monitoring::AveragingCounter<>::DeviceType n_downstream_tracks,
    Allen::Monitoring::Histogram<>::DeviceType n_downstream_tracks_event,
    Allen::Monitoring::Histogram<>::DeviceType downstream_track_eta,
    Allen::Monitoring::Histogram<>::DeviceType downstream_track_phi,
    Allen::Monitoring::Histogram<>::DeviceType downstream_track_nhits);

  struct downstream_v2_consolidate_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};

    Allen::Monitoring::AveragingCounter<> m_downstream_tracks {this, "n_downstream_tracks"};
    Allen::Monitoring::Histogram<> m_histogram_n_downstream_tracks {this,
                                                                    "n_downstream_tracks_event",
                                                                    "n_downstream_tracks_event",
                                                                    {201u, -0.5f, 200.5f}};
    Allen::Monitoring::Histogram<> m_histogram_downstream_track_eta {this,
                                                                     "downstream_track_eta",
                                                                     "#eta",
                                                                     {400u, 0.f, 10.f}};
    Allen::Monitoring::Histogram<> m_histogram_downstream_track_phi {this,
                                                                     "downstream_track_phi",
                                                                     "#phi",
                                                                     {16u, -4.f, 4.f}};
    Allen::Monitoring::Histogram<> m_histogram_downstream_track_nhits {this,
                                                                       "downstream_track_nhits",
                                                                       "N. hits / track",
                                                                       {50u, 0.f, 50.f}};
  };

} // namespace downstream_v2_consolidate