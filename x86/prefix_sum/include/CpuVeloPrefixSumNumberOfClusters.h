#pragma once

#include "HostAlgorithm.cuh"
#include "CpuPrefixSum.h"

namespace cpu_velo_prefix_sum_number_of_clusters {
  // Arguments
  struct dev_estimated_input_size_t : output_datatype<uint>{};

  template<typename Arguments>
  struct cpu_velo_prefix_sum_number_of_clusters_t : public HostAlgorithm {
    constexpr static auto name {"cpu_velo_prefix_sum_number_of_clusters_t"};
    decltype(host_function(cpu_prefix_sum)) function {cpu_prefix_sum};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {}

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      // Invokes the function
      function(
        host_buffers.host_prefix_sum_buffer,
        host_buffers.host_allocated_prefix_sum_space,
        offset<dev_estimated_input_size_t>(arguments),
        size<dev_estimated_input_size_t>(arguments),
        cuda_stream,
        cuda_generic_event,
        host_buffers.host_total_number_of_velo_clusters);
    }
  };
} // namespace cpu_velo_prefix_sum_number_of_clusters