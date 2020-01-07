#pragma once

#include "HostAlgorithm.cuh"
#include "CpuPrefixSum.h"
#include "ArgumentsSciFi.cuh"

struct cpu_scifi_prefix_sum_number_of_tracks_t : public HostAlgorithm {
  constexpr static auto name {"cpu_scifi_prefix_sum_number_of_tracks_t"};
  decltype(host_function(cpu_prefix_sum)) function {cpu_prefix_sum};
  using Arguments = std::tuple<dev_atomics_scifi>;

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
    cudaEvent_t& cuda_generic_event) const;
};
