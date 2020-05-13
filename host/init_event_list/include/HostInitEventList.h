#pragma once

#include "HostAlgorithm.cuh"

namespace host_init_event_list {
  struct Parameters {
    HOST_INPUT(host_ut_raw_banks_t, gsl::span<char const>) ut_banks;
    HOST_INPUT(host_ut_raw_offsets_t, gsl::span<unsigned int const>) ut_offsets;
    HOST_INPUT(host_scifi_raw_banks_t, gsl::span<char const>) scifi_banks;
    HOST_INPUT(host_scifi_raw_offsets_t, gsl::span<unsigned int const>) scifi_offsets;
    HOST_OUTPUT(host_total_number_of_events_t, uint);
    HOST_OUTPUT(host_event_list_t, uint);
    HOST_OUTPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_event_list_t, uint) dev_event_list;
  };

  // Algorithm
  template<typename T>
  struct host_init_event_list_t : public HostAlgorithm, Parameters {


    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto event_end = std::get<1>(runtime_options.event_interval);
      
      set_size<host_total_number_of_events_t>(arguments, 1);
      set_size<host_number_of_selected_events_t>(arguments, 1);
      set_size<host_event_list_t>(arguments, event_end - event_start);
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
      data<host_total_number_of_events_t>(arguments)[0] = number_of_events;
      data<host_number_of_selected_events_t>(arguments)[0] = number_of_events;
      for (uint i = 0; i < number_of_events; ++i) {
        data<host_event_list_t>(arguments)[i] = i;
      }

      cudaCheck(cudaMemcpyAsync(
        data<dev_event_list_t>(arguments),
        data<host_event_list_t>(arguments),
        size<dev_event_list_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));
    }
  };
} // namespace host_init_event_list