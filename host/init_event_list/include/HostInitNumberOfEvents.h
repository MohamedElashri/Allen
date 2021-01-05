#pragma once

#include "HostAlgorithm.cuh"

namespace host_init_number_of_events {
  struct Parameters {
    HOST_OUTPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_OUTPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
  };

  // Algorithm
  struct host_init_number_of_events_t : public HostAlgorithm, Parameters {
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
      const Allen::Context& context) const;
  };
} // namespace host_init_number_of_events