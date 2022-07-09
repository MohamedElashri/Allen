/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VeloEventModel.cuh"
#include "VeloDefinitions.cuh"
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "TrackMatchingConstants.cuh"
#include "AlgorithmTypes.cuh"

namespace track_matching_veloSciFi {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_seeding_confirmTracks_atomics_t, unsigned) dev_atomics_scifi;

    DEVICE_INPUT(dev_offsets_all_seeding_tracks_t, unsigned) dev_atomics_seeding;
    DEVICE_INPUT(dev_offsets_scifi_seed_hit_number_t, unsigned) dev_seeding_hit_number;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_INPUT(dev_seeding_track_hits_t, char) dev_seeding_track_hits;

    DEVICE_INPUT(dev_scifi_track_seeds_t, SciFi::Seeding::Track) dev_scifi_track_seeds;

    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Velo::Consolidated::States) dev_velo_states_view;

    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_t, unsigned) dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;

    DEVICE_OUTPUT(dev_atomics_matched_tracks_t, unsigned) dev_atomics_matched_tracks;
    DEVICE_OUTPUT(dev_matched_tracks_t, SciFi::MatchedTrack) dev_matched_tracks;

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };
  __global__ void track_matching_veloSciFi(
    Parameters,
    const TrackMatchingConsts::MagnetParametrization* dev_magnet_parametrization);

  struct track_matching_veloSciFi_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

} // namespace track_matching_veloSciFi
