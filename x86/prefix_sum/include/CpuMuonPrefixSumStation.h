#pragma once

#include "HostAlgorithm.cuh"
#include "CpuPrefixSum.h"
#include "ArgumentsMuon.cuh"

struct cpu_muon_prefix_sum_station_t : public HostAlgorithm {
  constexpr static auto name {"cpu_muon_prefix_sum_station_t"};
  decltype(host_function(cpu_prefix_sum)) function {cpu_prefix_sum};
  using Arguments = std::tuple<dev_station_ocurrences_offset>;

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
    cudaEvent_t& cuda_generic_event) const;
};
