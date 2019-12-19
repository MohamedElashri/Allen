#pragma once

#include "Common.h"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "GlobalEventCutConfiguration.cuh"
#include "CpuAlgorithm.cuh"

namespace host_global_event_cut {
  // Arguments
  HOST_OUTPUT(host_event_list_t, uint)
  HOST_OUTPUT(host_number_of_selected_events_t, uint)
  DEVICE_OUTPUT(dev_event_list_t, uint)

  // Function
  void host_global_event_cut(
    const char* ut_raw_input,
    const uint* ut_raw_input_offsets,
    const char* scifi_raw_input,
    const uint* scifi_raw_input_offsets,
    host_number_of_selected_events_t number_of_selected_events,
    host_event_list_t event_list,
    uint number_of_events);

  // Algorithm
  template<typename Arguments>
  struct host_global_event_cut_t : public HostAlgorithm {
    constexpr static auto name {"host_global_event_cut_t"};
    decltype(host_function(host_global_event_cut)) function {host_global_event_cut};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<host_number_of_selected_events_t>(arguments, 1);
      set_size<host_event_list_t>(arguments, runtime_options.number_of_events);
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
      offset<host_number_of_selected_events_t>(arguments)[0] = runtime_options.number_of_events;
      for (uint i = 0; i < runtime_options.number_of_events; ++i) {
        offset<host_event_list_t>(arguments)[i] = i;
      }

      function(
        std::get<0>(runtime_options.host_ut_events).begin(),
        std::get<1>(runtime_options.host_ut_events).begin(),
        std::get<0>(runtime_options.host_scifi_events).begin(),
        std::get<1>(runtime_options.host_scifi_events).begin(),
        offset<host_number_of_selected_events_t>(arguments),
        offset<host_event_list_t>(arguments),
        runtime_options.number_of_events);

      cudaCheck(cudaMemcpyAsync(
        offset<dev_event_list_t>(arguments),
        offset<host_event_list_t>(arguments),
        size<dev_event_list_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));

      // TODO: Remove
      host_buffers.host_number_of_selected_events[0] = value<host_number_of_selected_events_t>(arguments);
      for (uint i = 0; i < runtime_options.number_of_events; ++i) {
        host_buffers.host_event_list[i] = offset<host_event_list_t>(arguments)[i];
      }
    }
  };
} // namespace cpu_global_event_cut