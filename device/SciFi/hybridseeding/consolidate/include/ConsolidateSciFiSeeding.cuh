/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"

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
      DEPENDENCIES(dev_scifi_hits_view_t),
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
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };
  __global__ void seed_confirmTracks_consolidate(Parameters, const float* dev_magnet_polarity);

  struct seed_confirmTracks_consolidate_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace seed_confirmTracks_consolidate
