#pragma once

#include "HostAlgorithm.cuh"

namespace host_init_event_list {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_ut_raw_banks_t, gsl::span<char const>), ut_banks),
    (HOST_INPUT(host_ut_raw_offsets_t, gsl::span<unsigned int const>), ut_offsets),
    (HOST_INPUT(host_scifi_raw_banks_t, gsl::span<char const>), scifi_banks),
    (HOST_INPUT(host_scifi_raw_offsets_t, gsl::span<unsigned int const>), scifi_offsets),
    (HOST_OUTPUT(host_total_number_of_events_t, unsigned), host_total_number_of_events),
    (HOST_OUTPUT(host_event_list_t, unsigned), host_event_list),
    (HOST_OUTPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_OUTPUT(dev_event_list_t, unsigned), dev_event_list))

  // Algorithm
  struct host_init_event_list_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const;
  };
} // namespace host_init_event_list