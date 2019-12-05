#pragma once

#include "Common.h"
#include "Handler.cuh"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "ArgumentsCommon.cuh"
#include "GlobalEventCutConfiguration.cuh"
#include "CpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"

void cpu_global_event_cut(
  char const* ut_raw_input,
  uint const* ut_raw_input_offsets,
  char const* scifi_raw_input,
  uint const* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list,
  uint number_of_events);

struct cpu_global_event_cut_t : public CpuAlgorithm {
  constexpr static auto name {"cpu_global_event_cut_t"};
  decltype(cpu_function(cpu_global_event_cut)) algorithm {cpu_global_event_cut};
  using Arguments = std::tuple<dev_event_list>;

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
