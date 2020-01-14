#pragma once

#include "HostAlgorithm.cuh"

namespace host_init_event_list {
  struct Parameters {
    HOST_OUTPUT(host_event_list_t, uint);
    HOST_OUTPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_event_list_t, uint) dev_event_list;
  };

  // Algorithm
  template<typename T>
  struct host_init_event_list_t : public HostAlgorithm, Parameters {
    constexpr static auto name {"host_init_event_list_t"};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_event_list_t>(arguments, runtime_options.number_of_events);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      // Initialize buffers
      offset<host_number_of_selected_events_t>(arguments)[0] = runtime_options.number_of_events;
      for (uint i = 0; i < runtime_options.number_of_events; ++i) {
        offset<host_event_list_t>(arguments)[i] = i;
      }

      cudaCheck(cudaMemcpyAsync(
        offset<dev_event_list_t>(arguments),
        host_buffers.host_event_list,
        runtime_options.number_of_events * sizeof(uint),
        cudaMemcpyHostToDevice,
        cuda_stream));
    }
  };
} // namespace host_init_event_list