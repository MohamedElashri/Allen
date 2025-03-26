/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
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
#include "ParticleTypes.cuh"

// Event Model
#include "States.cuh"
#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "VeloConsolidated.cuh"

// Local
#include "DownstreamConstants.cuh"
#include "DownstreamStructs.cuh"

#include "AllenMonitoring.h"

/**
 * @brief This is difinition file for downstream consolidation algorithm
 * This algorithm is responsible for consolidating downstream tracks from the downstream hits
 * implementation file is downstream_consolidate.cu
 */

namespace downstream_consolidate {
  struct Parameters {
    // Basic input
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Host statistics
    HOST_INPUT(host_number_of_hits_in_downstream_tracks_t, unsigned) host_number_of_hits_in_downstream_tracks;
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;

    // Downstream input
    DEVICE_INPUT(dev_offsets_downstream_hit_numbers_t, unsigned) dev_offsets_downstream_hit_numbers;
    DEVICE_INPUT(dev_offsets_downstream_tracks_t, unsigned) dev_offsets_downstream_tracks;
    DEVICE_INPUT(dev_downstream_tracks_t, UT::DownstreamTrack) dev_downstream_tracks;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Scifi input
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;

    // Output
    DEVICE_OUTPUT(dev_downstream_track_states_t, char) dev_downstream_track_states;
    DEVICE_OUTPUT(dev_downstream_track_hits_t, char) dev_downstream_track_hits;
    DEVICE_OUTPUT(dev_downstream_track_qops_t, float) dev_downstream_track_qops;
    DEVICE_OUTPUT(dev_downstream_track_ghost_probability_t, float) dev_downstream_track_ghost_probability;
    DEVICE_OUTPUT(dev_downstream_track_scifi_idx_t, unsigned) dev_downstream_track_scifi_idx;
    DEVICE_OUTPUT(dev_downstream_track_scifi_states_t, MiniState) dev_downstream_track_scifi_states;

    //
    // Views outputs : UT tracks
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_hits_view_t,
      DEPENDENCIES(dev_scifi_tracks_view_t, dev_downstream_tracks_t, dev_downstream_track_hits_t),
      Allen::Views::UT::Consolidated::Hits)
    dev_downstream_hits_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_ut_track_view_t,
      DEPENDENCIES(dev_downstream_hits_view_t, dev_downstream_tracks_t, dev_downstream_track_hits_t),
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
      DEPENDENCIES(dev_scifi_tracks_view_t, dev_downstream_tracks_t, dev_downstream_track_states_t),
      Allen::Views::Physics::KalmanStates)
    dev_downstream_track_states_view;

    //
    // Views outputs : Downstream tracks
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_track_view_t,
      DEPENDENCIES(
        dev_offsets_downstream_tracks_t,
        dev_downstream_ut_tracks_view_t,
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

  __global__ void downstream_consolidate(
    Parameters,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::AveragingCounter<>::DeviceType);
  __global__ void downstream_create_tracks_view(
    Parameters,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType);

  struct lhcb_id_container_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct downstream_consolidate_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    __device__ static void monitor(
      const Allen::Views::Physics::DownstreamTrack downstream_track,
      const Allen::Views::Physics::KalmanState downstream_state,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&);

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};

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
} // namespace downstream_consolidate