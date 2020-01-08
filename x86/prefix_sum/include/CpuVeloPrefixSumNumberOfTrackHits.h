#pragma once

#include "HostAlgorithm.cuh"
#include "CpuPrefixSum.h"

namespace cpu_velo_prefix_sum_number_of_track_hits {
  // Arguments
  struct dev_velo_track_hit_number_t : output_datatype<uint> {};

  template<typename Arguments>
  struct cpu_velo_prefix_sum_number_of_track_hits_t : public HostAlgorithm {
    constexpr static auto name {"cpu_velo_prefix_sum_number_of_track_hits_t"};
    decltype(host_function(cpu_prefix_sum)) function {cpu_prefix_sum};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {}

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function(
        host_buffers.host_prefix_sum_buffer,
        host_buffers.host_allocated_prefix_sum_space,
        offset<dev_velo_track_hit_number_t>(arguments),
        size<dev_velo_track_hit_number_t>(arguments),
        cuda_stream,
        cuda_generic_event,
        host_buffers.host_accumulated_number_of_hits_in_velo_tracks);
    }
  };
} // namespace cpu_velo_prefix_sum_number_of_track_hits