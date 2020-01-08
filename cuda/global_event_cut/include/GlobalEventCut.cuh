#pragma once

#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "ArgumentsCommon.cuh"
#include "GlobalEventCutConfiguration.cuh"

__global__ void global_event_cut(
  char* dev_ut_raw_input,
  uint* dev_ut_raw_input_offsets,
  char* dev_scifi_raw_input,
  uint* dev_scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list);

struct global_event_cut_t : public DeviceAlgorithm {
  constexpr static auto name {"global_event_cut_t"};
  decltype(global_function(global_event_cut)) function {global_event_cut};
  using Arguments = std::tuple<
    dev_ut_raw_input,
    dev_ut_raw_input_offsets,
    dev_scifi_raw_input,
    dev_scifi_raw_input_offsets,
    dev_number_of_selected_events,
    dev_event_list>;

  void set_arguments_size(
    ArgumentRefManager<T> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<T>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
