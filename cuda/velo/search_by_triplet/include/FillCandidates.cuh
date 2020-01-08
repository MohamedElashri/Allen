#pragma once

#include "DeviceAlgorithm.cuh"

namespace velo_fill_candidates {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_total_number_of_velo_clusters_t, uint);
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, uint) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_cluster_num_t, uint) dev_module_cluster_num;
    DEVICE_INPUT(dev_hit_phi_t, float) dev_hit_phi;
    DEVICE_OUTPUT(dev_h0_candidates_t, short) dev_h0_candidates;
    DEVICE_OUTPUT(dev_h2_candidates_t, short) dev_h2_candidates;
  };

  __global__ void velo_fill_candidates(Arguments);

  template<typename T>
  struct velo_fill_candidates_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"velo_fill_candidates_t"};
    decltype(global_function(velo_fill_candidates)) function {velo_fill_candidates};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_h0_candidates_t>(arguments, 2 * value<host_total_number_of_velo_clusters_t>(arguments));
      set_size<dev_h2_candidates_t>(arguments, 2 * value<host_total_number_of_velo_clusters_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      cudaCheck(
        cudaMemsetAsync(offset<dev_h0_candidates_t>(arguments), 0, size<dev_h0_candidates_t>(arguments), cuda_stream));
      cudaCheck(
        cudaMemsetAsync(offset<dev_h2_candidates_t>(arguments), 0, size<dev_h2_candidates_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments), 48), block_dimension(), cuda_stream)(
        Arguments {
          offset<dev_sorted_velo_cluster_container_t>(arguments),
          offset<dev_offsets_estimated_input_size_t>(arguments),
          offset<dev_module_cluster_num_t>(arguments),
          offset<dev_hit_phi_t>(arguments),
          offset<dev_h0_candidates_t>(arguments),
          offset<dev_h2_candidates_t>(arguments)
        });
    }
  };
} // namespace velo_fill_candidates