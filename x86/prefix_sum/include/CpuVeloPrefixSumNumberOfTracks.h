#pragma once

#include "HostAlgorithm.cuh"
#include "CpuPrefixSum.h"

namespace cpu_velo_prefix_sum_number_of_tracks {
  // Arguments
  struct dev_atomics_velo_t : output_datatype<uint> {};

  template<typename Arguments>
  struct cpu_velo_prefix_sum_number_of_tracks_t : public HostAlgorithm {
    constexpr static auto name {"cpu_velo_prefix_sum_number_of_tracks_t"};
    decltype(host_function(cpu_prefix_sum)) function {cpu_prefix_sum};

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
      // Copy
      cudaCheck(cudaMemcpyAsync(
        (uint*) offset<dev_atomics_velo_t>(arguments) + host_buffers.host_number_of_selected_events[0],
        (uint*) offset<dev_atomics_velo_t>(arguments),
        host_buffers.host_number_of_selected_events[0] * sizeof(uint),
        cudaMemcpyDeviceToDevice,
        cuda_stream));

      // Prefix sum
      function.invoke(
        host_buffers.host_prefix_sum_buffer,
        host_buffers.host_allocated_prefix_sum_space,
        (uint*) offset<dev_atomics_velo_t>(arguments) + host_buffers.host_number_of_selected_events[0],
        (host_buffers.host_number_of_selected_events[0] + 1) * sizeof(uint),
        cuda_stream,
        cuda_generic_event,
        host_buffers.host_number_of_reconstructed_velo_tracks);
    }
  };
} // namespace cpu_velo_prefix_sum_number_of_tracks