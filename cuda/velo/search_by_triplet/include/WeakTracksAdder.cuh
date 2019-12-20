#pragma once

#include "VeloEventModel.cuh"
#include "GpuAlgorithm.cuh"
#include "States.cuh"

namespace velo_weak_tracks_adder {
  // Arguments
  HOST_INPUT(host_number_of_selected_events_t, uint)
  DEVICE_INPUT(dev_sorted_velo_cluster_container_t, uint)
  DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint)
  DEVICE_OUTPUT(dev_tracks_t, Velo::TrackHits)
  DEVICE_OUTPUT(dev_weak_tracks_t, Velo::TrackletHits)
  DEVICE_OUTPUT(dev_hit_used_t, bool)
  DEVICE_OUTPUT(dev_atomics_velo_t, uint)
  DEVICE_OUTPUT(dev_number_of_velo_tracks_t, uint)

  __global__ void velo_weak_tracks_adder(
    dev_sorted_velo_cluster_container_t,
    dev_offsets_estimated_input_size_t,
    dev_tracks_t,
    dev_weak_tracks_t,
    dev_hit_used_t,
    dev_atomics_velo_t,
    dev_number_of_velo_tracks_t);

  template<typename Arguments>
  struct velo_weak_tracks_adder_t : public DeviceAlgorithm {
    constexpr static auto name {"velo_weak_tracks_adder_t"};
    decltype(global_function(velo_weak_tracks_adder)) function {velo_weak_tracks_adder};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {}

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        offset<dev_sorted_velo_cluster_container_t>(arguments),
        offset<dev_offsets_estimated_input_size_t>(arguments),
        offset<dev_tracks_t>(arguments),
        offset<dev_weak_tracks_t>(arguments),
        offset<dev_hit_used_t>(arguments),
        offset<dev_atomics_velo_t>(arguments),
        offset<dev_number_of_velo_tracks_t>(arguments));
    }
  };
} // namespace velo_weak_tracks_adder