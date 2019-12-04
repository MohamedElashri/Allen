#pragma once

#include "CpuAlgorithm.cuh"
#include "CpuPrefixSum.h"
#include "ArgumentsVelo.cuh"

struct cpu_prefix_sum_velo_clusters_t {
  constexpr static auto name {"cpu_prefix_sum_velo_clusters_t"};
  decltype(cpu_algorithm(cpu_prefix_sum)) algorithm {cpu_prefix_sum};
  using Arguments = std::tuple<dev_estimated_input_size>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void visit(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
