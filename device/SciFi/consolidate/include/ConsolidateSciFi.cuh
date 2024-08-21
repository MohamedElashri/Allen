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

#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "UTConsolidated.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "LookingForwardConstants.cuh"
#include "ParticleTypes.cuh"
#include "CopyTrackParameters.cuh"

#include "AllenMonitoring.h"

namespace scifi_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_hits_in_scifi_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_scifi_tracks;
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, unsigned) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_tracks_t, SciFi::TrackHits) dev_scifi_tracks;
    DEVICE_INPUT(dev_scifi_lf_parametrization_consolidate_t, float) dev_scifi_lf_parametrization_consolidate;
    DEVICE_OUTPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_OUTPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_OUTPUT(dev_scifi_ghost_probability_t, float) dev_scifi_ghost_probability;
    DEVICE_OUTPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_OUTPUT(dev_scifi_track_ut_indices_t, unsigned) dev_scifi_track_ut_indices;
    HOST_INPUT(host_scifi_hit_count_t, unsigned) host_scifi_hit_count;
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
    DEVICE_OUTPUT(dev_used_scifi_hits_t, unsigned) dev_used_scifi_hits;
    DEVICE_OUTPUT(dev_used_ut_hits_offsets_t, unsigned) dev_used_ut_hits_offsets;
    DEVICE_OUTPUT(dev_accepted_and_unused_velo_tracks_t, bool) dev_accepted_and_unused_velo_tracks;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_hits_view_t,
      DEPENDENCIES(dev_scifi_track_hits_t),
      Allen::Views::SciFi::Consolidated::Hits)
    dev_scifi_hits_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_track_view_t,
      DEPENDENCIES(dev_scifi_hits_view_t, dev_tracks_view_t, dev_scifi_qop_t),
      Allen::Views::SciFi::Consolidated::Track)
    dev_scifi_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_tracks_view_t,
      DEPENDENCIES(dev_scifi_track_view_t),
      Allen::Views::SciFi::Consolidated::Tracks)
    dev_scifi_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_multi_event_tracks_view_t,
      DEPENDENCIES(dev_scifi_tracks_view_t),
      Allen::Views::SciFi::Consolidated::MultiEventTracks)
    dev_scifi_multi_event_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_track_view_t,
      DEPENDENCIES(dev_scifi_multi_event_tracks_view_t, dev_tracks_view_t, dev_scifi_ghost_probability_t),
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

  __global__ void scifi_consolidate_tracks(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_long_tracks_forward,
    Allen::Monitoring::AveragingCounter<>::DeviceType dev_n_long_tracks_forward_counter);

  struct scifi_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

    __device__ static void monitor(
      const Allen::Views::Physics::LongTrack long_track,
      const Allen::Views::Physics::KalmanState velo_state,
      Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_eta,
      Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_phi,
      Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_nhits,
      Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_qop);

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};

    Allen::Monitoring::AveragingCounter<> m_counter_long_tracks_forward {this, "n_long_tracks_forward"};

    Allen::Monitoring::Histogram<> m_histogram_n_long_tracks_forward {this,
                                                                      "n_long_tracks_forward_event",
                                                                      "n_long_tracks_forward_event",
                                                                      {201, -0.5f, 200.5f}};

    Allen::Monitoring::Histogram<> m_histogram_long_track_forward_eta {this,
                                                                       "long_track_forward_eta",
                                                                       "#eta",
                                                                       {400, 0.f, 10.f}};

    Allen::Monitoring::Histogram<> m_histogram_long_track_forward_phi {this,
                                                                       "long_track_forward_phi",
                                                                       "#phi",
                                                                       {16, -4.f, 4.f}};

    Allen::Monitoring::Histogram<> m_histogram_long_track_forward_nhits {this,
                                                                         "long_track_forward_nhits",
                                                                         "N. hits / track",
                                                                         {51, -0.5f, 50.5f}};
    Allen::Monitoring::Histogram<> m_histogram_long_track_forward_qop {this,
                                                                       "long_track_forward_qop",
                                                                       "q/p",
                                                                       {200u, -1e-3f, 1e-3f}};
  };

} // namespace scifi_consolidate_tracks
