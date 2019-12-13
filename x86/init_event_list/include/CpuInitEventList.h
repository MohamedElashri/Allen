#pragma once

#include "CpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"

namespace cpu_init_event_list {
  // Arguments
  struct dev_event_list_t : output_datatype<uint> {};

  // Algorithm
  template<typename Arguments>
  struct cpu_init_event_list_t : public CpuAlgorithm {
    constexpr static auto name {"cpu_init_event_list_t"};

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
      // Initialize buffers
      host_buffers.host_number_of_selected_events[0] = runtime_options.number_of_events;
      for (uint i = 0; i < runtime_options.number_of_events; ++i) {
        host_buffers.host_event_list[i] = i;
      }

      cudaCheck(cudaMemcpyAsync(
        offset<dev_event_list_t>(arguments),
        host_buffers.host_event_list,
        runtime_options.number_of_events * sizeof(uint),
        cudaMemcpyHostToDevice,
        cuda_stream));
    }
  };
} // namespace cpu_init_event_list