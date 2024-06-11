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

#include "States.cuh"
#include "ParticleTypes.cuh"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"
#include "TrackMatchingConstants.cuh"
#include "AlgorithmTypes.cuh"
#include "CopyTrackParameters.cuh"

#include "AllenMonitoring.h"

namespace matching_consolidate_tracks {
  struct Parameters {
    // Basics
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Velo tracks
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;

    // Scifi Trcaks
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;

    // UT Hits
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Matched results (VeloScifi/General part)
    HOST_INPUT(host_number_of_reconstructed_matched_tracks_t, unsigned) host_number_of_reconstructed_matched_tracks;
    DEVICE_INPUT(dev_offsets_matched_tracks_t, unsigned) dev_offsets_matched_tracks;
    DEVICE_INPUT(dev_matched_tracks_t, SciFi::MatchedTrack) dev_matched_tracks;

    // Matched results (UT part)
    HOST_INPUT(host_accumulated_number_of_ut_hits_in_matched_tracks_t, unsigned)
    host_accumulated_number_of_ut_hits_in_matched_tracks;
    DEVICE_INPUT(dev_offsets_matched_ut_hit_number_t, unsigned) dev_offsets_matched_ut_hit_number;

    // Working memory (Temporal)
    DEVICE_OUTPUT(dev_matched_track_velo_indices_t, unsigned) dev_matched_track_velo_indices;
    DEVICE_OUTPUT(dev_matched_track_scifi_indices_t, unsigned) dev_matched_track_scifi_indices;

    // Outputs (VeloScifi/General part)
    DEVICE_OUTPUT(dev_matched_qop_t, float) dev_matched_qop;                             // For event model
    DEVICE_OUTPUT(dev_matched_ghost_probability_t, float) dev_matched_ghost_probability; // For event model
    DEVICE_OUTPUT(dev_scifi_states_t, MiniState) dev_scifi_states;                       // Align with Forward output
    DEVICE_OUTPUT(dev_accepted_and_unused_velo_tracks_t, bool)
    dev_accepted_and_unused_velo_tracks; // For Forward + Matching mode
    DEVICE_OUTPUT(dev_matched_is_scifi_track_used_t, bool) dev_matched_is_scifi_track_used; // For Downstream tracking

    // Outputs (UT part)
    DEVICE_OUTPUT(dev_matched_ut_track_hits_t, char) dev_matched_ut_track_hits;
    DEVICE_OUTPUT(dev_used_ut_hits_t, unsigned) dev_used_ut_hits;

    // UT tracks views
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_matched_ut_track_hits_view_t,
      DEPENDENCIES(dev_matched_ut_track_hits_t),
      Allen::Views::UT::Consolidated::Hits)
    dev_matched_ut_track_hits_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_matched_ut_track_view_t,
      DEPENDENCIES(dev_matched_ut_track_hits_view_t),
      Allen::Views::UT::Consolidated::Track)
    dev_matched_ut_track_view;

    // Long tracks views
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_track_view_t,
      DEPENDENCIES(
        dev_matched_ut_track_view_t,
        dev_scifi_tracks_view_t,
        dev_velo_tracks_view_t,
        dev_matched_qop_t,
        dev_matched_ghost_probability_t),
      Allen::Views::Physics::LongTrack)
    dev_long_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_tracks_view_t,
      DEPENDENCIES(dev_long_track_view_t),
      Allen::Views::Physics::LongTracks)
    dev_long_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_long_tracks_view_t,
      DEPENDENCIES(dev_long_tracks_view_t),
      Allen::Views::Physics::MultiEventLongTracks)
    dev_multi_event_long_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_long_tracks_ptr_t,
      DEPENDENCIES(dev_multi_event_long_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_long_tracks_ptr;

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  template<bool has_ut>
  __global__ void matching_create_longtracks_views(Parameters parameters);

  template<bool has_ut>
  __global__ void matching_consolidate_tracks(
    Parameters,
    const unsigned*,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::AveragingCounter<>::DeviceType);

  struct matching_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    __device__ static void monitor(
      const SciFi::MatchedTrack matched_track,
      const Allen::Views::SciFi::Consolidated::Track scifi_track,
      const Allen::Views::Velo::Consolidated::Track velo_track,
      const Allen::Views::Physics::KalmanState velo_state,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&);

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};

    Allen::Monitoring::AveragingCounter<> m_long_tracks_matching {this, "n_long_tracks_matching"};
    Allen::Monitoring::Histogram<> m_histogram_n_long_tracks_matching {this,
                                                                       "n_long_tracks_matching_event",
                                                                       "n_long_tracks_matching_event",
                                                                       {501u, -0.5f, 500.5f}};
    Allen::Monitoring::Histogram<> m_histogram_long_track_matching_eta {this,
                                                                        "long_track_matching_eta",
                                                                        "#eta",
                                                                        {400u, 0.f, 10.f}};
    Allen::Monitoring::Histogram<> m_histogram_long_track_matching_phi {this,
                                                                        "long_track_matching_phi",
                                                                        "#phi",
                                                                        {160u, -4.f, 4.f}};
    Allen::Monitoring::Histogram<> m_histogram_long_track_matching_nhits {this,
                                                                          "long_track_matching_nhits",
                                                                          "N. hits / track",
                                                                          {51u, -0.5f, 50.5f}};
    Allen::Monitoring::Histogram<> m_histogram_long_track_matching_qop {this,
                                                                        "long_track_matching_qop",
                                                                        "q/p",
                                                                        {200u, -1e-3f, 1e-3f}};
    Allen::Monitoring::Histogram<> m_histogram_long_track_ghost_prob {this,
                                                                      "long_track_ghost_prob",
                                                                      "GhostProb",
                                                                      {100u, 0.f, 0.6f}};
  };
} // namespace matching_consolidate_tracks
