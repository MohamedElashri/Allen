/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "Common.h"
#include "AlgorithmTypes.cuh"
#include <cstdint>

namespace velo_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_accumulated_number_of_hits_in_velo_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_velo_tracks;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    HOST_INPUT(host_number_of_three_hit_tracks_filtered_t, unsigned) host_number_of_three_hit_tracks_filtered;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, unsigned)
    dev_offsets_number_of_three_hit_tracks_filtered;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
    DEVICE_OUTPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_hits_view_t,
      DEPENDENCIES(dev_velo_track_hits_t, dev_offsets_all_velo_tracks_t, dev_offsets_velo_track_hit_number_t),
      Allen::Views::Velo::Consolidated::Hits)
    dev_velo_hits_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_track_view_t,
      DEPENDENCIES(
        dev_velo_hits_view_t,
        dev_velo_track_hits_t,
        dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t),
      Allen::Views::Velo::Consolidated::Track)
    dev_velo_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_tracks_view_t,
      DEPENDENCIES(
        dev_velo_hits_view_t,
        dev_velo_track_view_t,
        dev_velo_track_hits_t,
        dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t),
      Allen::Views::Velo::Consolidated::Tracks)
    dev_velo_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_multi_event_tracks_view_t,
      DEPENDENCIES(
        dev_velo_hits_view_t,
        dev_velo_track_view_t,
        dev_velo_tracks_view_t,
        dev_velo_track_hits_t,
        dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t),
      Allen::Views::Velo::Consolidated::MultiEventTracks)
    dev_velo_multi_event_tracks_view;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void velo_consolidate_tracks(Parameters);

  struct lhcb_id_container_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct velo_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    using contracts = std::tuple<lhcb_id_container_checks>;

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
  };
} // namespace velo_consolidate_tracks