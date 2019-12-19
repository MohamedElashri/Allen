#pragma once

#include "GpuAlgorithm.cuh"

namespace velo_fill_candidates {
  // Arguments
  HOST_INPUT(host_number_of_selected_events_t, uint)
  HOST_INPUT(host_total_number_of_velo_clusters_t, uint)
  DEVICE_INPUT(dev_velo_cluster_container_t, uint)
  DEVICE_INPUT(dev_estimated_input_size_t, uint)
  DEVICE_INPUT(dev_module_cluster_num_t, uint)
  DEVICE_OUTPUT(dev_h0_candidates_t, short)
  DEVICE_OUTPUT(dev_h2_candidates_t, short)

  __global__ void velo_fill_candidates(
    dev_velo_cluster_container_t dev_velo_cluster_container,
    dev_estimated_input_size_t dev_estimated_input_size,
    dev_module_cluster_num_t dev_module_cluster_num,
    dev_h0_candidates_t dev_h0_candidates,
    dev_h2_candidates_t dev_h2_candidates);

  template<typename Arguments>
  struct velo_fill_candidates_t : public DeviceAlgorithm {
    constexpr static auto name {"velo_fill_candidates_t"};
    decltype(global_function(velo_fill_candidates)) function {velo_fill_candidates};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_h0_candidates_t>(arguments, 2 * offset<host_total_number_of_velo_clusters_t>(arguments)[0]);
      set_size<dev_h2_candidates_t>(arguments, 2 * offset<host_total_number_of_velo_clusters_t>(arguments)[0]);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function.invoke(dim3(offset<host_number_of_selected_events_t>(arguments)[0], 48), block_dimension(), cuda_stream)(
        offset<dev_velo_cluster_container_t>(arguments),
        offset<dev_estimated_input_size_t>(arguments),
        offset<dev_module_cluster_num_t>(arguments),
        offset<dev_h0_candidates_t>(arguments),
        offset<dev_h2_candidates_t>(arguments));
    }
  };
} // namespace velo_fill_candidates