/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "AlgorithmTypes.cuh"

namespace ut_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, unsigned) host_number_of_reconstructed_ut_tracks;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_hits_in_ut_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_ut_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, unsigned) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_tracks_t, UT::TrackHits) dev_ut_tracks;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_OUTPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_OUTPUT(dev_ut_track_params_t, float) dev_ut_track_params;
    DEVICE_OUTPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_OUTPUT(dev_ut_track_velo_indices_t, unsigned) dev_ut_track_velo_indices;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_ut_hits_view_t,
      DEPENDENCIES(dev_ut_track_hits_t),
      Allen::Views::UT::Consolidated::Hits)
    dev_ut_hits_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_ut_track_view_t,
      DEPENDENCIES(dev_ut_hits_view_t, dev_velo_tracks_view_t, dev_ut_track_velo_indices_t, dev_ut_track_params_t),
      Allen::Views::UT::Consolidated::Track)
    dev_ut_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_ut_tracks_view_t,
      DEPENDENCIES(dev_ut_track_view_t),
      Allen::Views::UT::Consolidated::Tracks)
    dev_ut_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_ut_multi_event_tracks_view_t,
      DEPENDENCIES(dev_ut_tracks_view_t),
      Allen::Views::UT::Consolidated::MultiEventTracks)
    dev_ut_multi_event_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_imec_ut_tracks_t,
      DEPENDENCIES(dev_ut_multi_event_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_imec_ut_tracks;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void ut_consolidate_tracks(Parameters, const unsigned* dev_unique_x_sector_layer_offsets);

  struct lhcb_id_container_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct ut_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace ut_consolidate_tracks