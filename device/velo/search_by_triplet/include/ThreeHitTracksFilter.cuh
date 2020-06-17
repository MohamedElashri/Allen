#pragma once

#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "States.cuh"

namespace velo_three_hit_tracks_filter {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char), dev_sorted_velo_cluster_container),
    (DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned), dev_offsets_estimated_input_size),
    (DEVICE_INPUT(dev_three_hit_tracks_input_t, Velo::TrackletHits), dev_three_hit_tracks_input),
    (DEVICE_INPUT(dev_atomics_velo_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_hit_used_t, bool), dev_hit_used),
    (DEVICE_OUTPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits), dev_three_hit_tracks_output),
    (DEVICE_OUTPUT(dev_number_of_three_hit_tracks_output_t, unsigned), dev_number_of_three_hit_tracks_output),

    // Max chi2
    (PROPERTY(max_chi2_t, "max_chi2", "chi2", float), max_chi2),

    // Maximum number of tracks to follow at a time
    (PROPERTY(max_weak_tracks_t, "max_weak_tracks", "max weak tracks", unsigned), max_weak_tracks),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void velo_three_hit_tracks_filter(Parameters);

  struct velo_three_hit_tracks_filter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<max_chi2_t> m_chi2 {this, 20.0f};
    Property<max_weak_tracks_t> m_max_weak {this, 500u};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_three_hit_tracks_filter