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

#include "SciFiDefinitions.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "CopyTrackParameters.cuh"

#include "AllenMonitoring.h"

namespace seed_confirmTracks_consolidate {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_seeding_tracks_t, unsigned) host_number_of_reconstructed_seeding_tracks;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_hits_in_scifi_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_offsets_seeding_tracks_t, unsigned) dev_atomics_scifi;          // fishy
    DEVICE_INPUT(dev_offsets_seeding_hit_number_t, unsigned) dev_seeding_hit_number; // fishy
    DEVICE_INPUT(dev_seeding_tracks_t, SciFi::Seeding::Track) dev_seeding_tracks;
    DEVICE_OUTPUT(dev_seeding_qop_t, float) dev_seeding_qop;
    DEVICE_OUTPUT(dev_seeding_chi2Y_t, float) dev_seeding_chi2Y;
    // DEVICE_OUTPUT(dev_seeding_chi2X_t, float) dev_seeding_chi2X;
    // DEVICE_OUTPUT(dev_seeding_nY_t, int) dev_seeding_nY;
    DEVICE_OUTPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_OUTPUT(dev_seeding_track_hits_t, char) dev_seeding_track_hits;
    HOST_INPUT(host_scifi_hit_count_t, unsigned) host_scifi_hit_count;
    DEVICE_OUTPUT(dev_used_scifi_hits_t, unsigned) dev_used_scifi_hits;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_hits_view_t,
      DEPENDENCIES(dev_seeding_track_hits_t),
      Allen::Views::SciFi::Consolidated::Hits)
    dev_scifi_hits_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_track_view_t,
      DEPENDENCIES(dev_scifi_hits_view_t, dev_seeding_qop_t),
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
  };
  __global__ void seed_confirmTracks_consolidate(
    Parameters,
    const float* dev_magnet_polarity,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::AveragingCounter<>::DeviceType);

  struct seed_confirmTracks_consolidate_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    __device__ static void monitor(
      SciFi::Seeding::Track scifi_track,
      MiniState scifi_state,
      float qop,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&,
      Allen::Monitoring::Histogram<>::DeviceType&);

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};

    Allen::Monitoring::AveragingCounter<> m_seed_tracks {this, "n_seed_tracks"};
    Allen::Monitoring::Histogram<> m_histogram_n_scifi_seeds {this,
                                                              "n_scifi_seeds_event",
                                                              "n_scifi_seeds_event",
                                                              {501u, -0.5f, 500.5f}};
    Allen::Monitoring::Histogram<> m_histogram_scifi_track_eta {this, "scifi_track_eta", "#eta", {400u, 0.f, 10.f}};
    Allen::Monitoring::Histogram<> m_histogram_scifi_track_phi {this, "scifi_track_phi", "#phi", {160u, -4.f, 4.f}};
    Allen::Monitoring::Histogram<> m_histogram_scifi_track_nhits {this,
                                                                  "scifi_track_nhits",
                                                                  "N. hits / track",
                                                                  {15u, -0.5f, 14.5f}};
    Allen::Monitoring::Histogram<> m_histogram_scifi_track_qop {this, "scifi_track_qop", "q/p", {200u, -1e-3f, 1e-3f}};
  };
} // namespace seed_confirmTracks_consolidate
