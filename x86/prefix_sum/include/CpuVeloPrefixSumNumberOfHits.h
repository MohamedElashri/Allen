#pragma once

#include "CpuAlgorithm.cuh"
#include "CpuPrefixSum.h"
#include "ArgumentsVelo.cuh"

struct cpu_velo_prefix_sum_number_of_hits_t : public CpuAlgorithm {
  constexpr static auto name {"cpu_velo_prefix_sum_number_of_hits_t"};
  decltype(cpu_function(cpu_prefix_sum)) algorithm {cpu_prefix_sum};
  using Arguments = std::tuple<dev_velo_track_hit_number>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const {}

  void visit(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
