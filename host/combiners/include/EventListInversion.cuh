#pragma once

#include "HostAlgorithm.cuh"

namespace event_list_inversion {
  struct Parameters {
    DEVICE_INPUT(dev_event_list_input_t, unsigned) dev_event_list;
    HOST_OUTPUT(host_event_list_t, unsigned) host_event_list;
    HOST_OUTPUT(host_event_list_output_t, unsigned) host_event_list_output;
    DEVICE_OUTPUT(dev_event_list_output_t, unsigned) dev_event_list_output;
  };

  struct event_list_inversion_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;
  };
} // namespace event_list_inversion