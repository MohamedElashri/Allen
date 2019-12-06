#pragma once

#include "CpuAlgorithm.cuh"
#include "CpuPrefixSum.h"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsVertex.cuh"

struct cpu_sv_prefix_sum_offsets_t : public CpuAlgorithm {
  constexpr static auto name {"cpu_sv_prefix_sum_offsets_t"};
  decltype(cpu_function(cpu_prefix_sum)) function {cpu_prefix_sum};
  using Arguments = std::tuple<dev_sv_offsets, dev_atomics_scifi>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
