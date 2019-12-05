#pragma once

#include "CpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"

// Note: In certain cases, a CpuAlgorithm may have all its
//       functionality in its "visit" method. Hence, an empty_function
//       is provided to allow defining CpuFunctions for those cases.
void empty_function();

struct cpu_init_event_list_t : public CpuAlgorithm {
  constexpr static auto name {"cpu_init_event_list_t"};
  decltype(cpu_function(empty_function)) algorithm {empty_function};
  using Arguments = std::tuple<dev_event_list>;

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
