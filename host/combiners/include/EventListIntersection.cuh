#pragma once

#include "HostAlgorithm.cuh"

namespace event_list_intersection {
  struct Parameters {
    DEVICE_INPUT(dev_event_list_a_t, unsigned) dev_event_list_a;
    DEVICE_INPUT(dev_event_list_b_t, unsigned) dev_event_list_b;
    HOST_OUTPUT(host_event_list_a_t, unsigned) host_event_list_a;
    HOST_OUTPUT(host_event_list_b_t, unsigned) host_event_list_b;
    HOST_OUTPUT(host_event_list_output_t, unsigned) host_event_list_output;
    DEVICE_OUTPUT(dev_event_list_output_t, unsigned) dev_event_list_output;
  };

  struct event_list_intersection_t : public HostAlgorithm, Parameters {
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
} // namespace event_list_intersection