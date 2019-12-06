#pragma once

#include "CpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"

struct cpu_init_event_list_t : public CpuAlgorithm {
  constexpr static auto name {"cpu_init_event_list_t"};
  using Arguments = std::tuple<dev_event_list>;

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
