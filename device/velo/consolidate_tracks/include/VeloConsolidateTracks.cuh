/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include <cstdint>

namespace velo_consolidate_tracks {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_accumulated_number_of_hits_in_velo_tracks_t, unsigned),
     host_accumulated_number_of_hits_in_velo_tracks),
    (HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned), host_number_of_reconstructed_velo_tracks),
    (HOST_INPUT(host_number_of_three_hit_tracks_filtered_t, unsigned), host_number_of_three_hit_tracks_filtered),
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_offsets_all_velo_tracks),
    (DEVICE_INPUT(dev_tracks_t, Velo::TrackHits), dev_tracks),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_offsets_velo_track_hit_number),
    (DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char), dev_sorted_velo_cluster_container),
    (DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned), dev_offsets_estimated_input_size),
    (DEVICE_INPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits), dev_three_hit_tracks_output),
    (DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, unsigned),
     dev_offsets_number_of_three_hit_tracks_filtered),
    (DEVICE_INPUT(dev_number_of_events_t, unsigned), dev_number_of_events),
    (DEVICE_OUTPUT(dev_accepted_velo_tracks_t, bool), dev_accepted_velo_tracks),
    (DEVICE_OUTPUT(dev_velo_states_t, char), dev_velo_states),
    (DEVICE_OUTPUT(dev_velo_track_hits_t, char), dev_velo_track_hits),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void velo_consolidate_tracks(Parameters);

  struct velo_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_consolidate_tracks