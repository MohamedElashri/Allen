#pragma once

#include "GpuAlgorithm.cuh"

namespace velo_fill_candidates {
  // Arguments
  struct dev_velo_cluster_container_t : input_datatype<uint> {};
  struct dev_estimated_input_size_t : input_datatype<uint> {};
  struct dev_module_cluster_num_t : input_datatype<uint> {};
  struct dev_h0_candidates_t : output_datatype<short> {};
  struct dev_h2_candidates_t : output_datatype<short> {};

  __global__ void velo_fill_candidates(
    dev_velo_cluster_container_t dev_velo_cluster_container,
    dev_estimated_input_size_t dev_estimated_input_size,
    dev_module_cluster_num_t dev_module_cluster_num,
    dev_h0_candidates_t dev_h0_candidates,
    dev_h2_candidates_t dev_h2_candidates);

  template<typename Arguments>
  struct velo_fill_candidates_t : public GpuAlgorithm {
    constexpr static auto name {"velo_fill_candidates_t"};
    decltype(gpu_function(velo_fill_candidates)) function {velo_fill_candidates};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_h0_candidates_t>(arguments, 2 * host_buffers.host_total_number_of_velo_clusters[0]);
      set_size<dev_h2_candidates_t>(arguments, 2 * host_buffers.host_total_number_of_velo_clusters[0]);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function.invoke(dim3(host_buffers.host_number_of_selected_events[0], 48), block_dimension(), cuda_stream)(
        offset<dev_velo_cluster_container_t>(arguments),
        offset<dev_estimated_input_size_t>(arguments),
        offset<dev_module_cluster_num_t>(arguments),
        offset<dev_h0_candidates_t>(arguments),
        offset<dev_h2_candidates_t>(arguments));
    }
  };
} // namespace velo_fill_candidates