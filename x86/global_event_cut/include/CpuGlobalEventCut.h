#pragma once

#include "Common.h"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "GlobalEventCutConfiguration.cuh"
#include "CpuAlgorithm.cuh"

namespace cpu_global_event_cut {
  // Arguments
  struct dev_event_list_t : output_datatype<uint> {};

  // Function
  void cpu_global_event_cut(
    const char* ut_raw_input,
    const uint* ut_raw_input_offsets,
    const char* scifi_raw_input,
    const uint* scifi_raw_input_offsets,
    uint* number_of_selected_events,
    uint* event_list,
    uint number_of_events);

  // Algorithm
  template<typename Arguments>
  struct cpu_global_event_cut_t : public CpuAlgorithm {
    constexpr static auto name {"cpu_global_event_cut_t"};
    decltype(cpu_function(cpu_global_event_cut)) function {cpu_global_event_cut};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_event_list_t>(arguments, runtime_options.number_of_events);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      // Initialize host event list
      host_buffers.host_number_of_selected_events[0] = runtime_options.number_of_events;
      for (uint i = 0; i < runtime_options.number_of_events; ++i) {
        host_buffers.host_event_list[i] = i;
      }

      function.invoke(
        std::get<0>(runtime_options.host_ut_events).begin(),
        std::get<1>(runtime_options.host_ut_events).begin(),
        std::get<0>(runtime_options.host_scifi_events).begin(),
        std::get<1>(runtime_options.host_scifi_events).begin(),
        host_buffers.host_number_of_selected_events,
        host_buffers.host_event_list,
        runtime_options.number_of_events);

      cudaCheck(cudaMemcpyAsync(
        offset<dev_event_list_t>(arguments),
        host_buffers.host_event_list,
        runtime_options.number_of_events * sizeof(uint),
        cudaMemcpyHostToDevice,
        cuda_stream));
    }
  };
} // namespace cpu_global_event_cut