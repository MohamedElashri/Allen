#pragma once

#include "HostAlgorithm.cuh"

namespace host_init_event_list {
  struct Parameters {
    HOST_OUTPUT(host_event_list_t, uint);
    HOST_OUTPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_event_list_t, uint) dev_event_list;
  };

  // Algorithm
  template<typename T, char... S>
  struct host_init_event_list_t : public HostAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto event_end = std::get<1>(runtime_options.event_interval);
      set_size<dev_event_list_t>(arguments, event_end - event_start);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto event_end = std::get<1>(runtime_options.event_interval);
      const auto number_of_events = event_end - event_start;

      // Initialize buffers
      begin<host_number_of_selected_events_t>(arguments)[0] = number_of_events;
      for (uint i = 0; i < number_of_events; ++i) {
        begin<host_event_list_t>(arguments)[i] = i;
      }

      cudaCheck(cudaMemcpyAsync(
        begin<dev_event_list_t>(arguments),
        host_buffers.host_event_list,
        size<dev_event_list_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));
    }
  };
} // namespace host_init_event_list