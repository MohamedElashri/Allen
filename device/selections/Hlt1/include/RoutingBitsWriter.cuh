/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "RoutingBitsConfiguration.cuh"
#include <string>

namespace routingbits_writer {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    HOST_INPUT(host_names_of_active_lines_t, char) host_names_of_active_lines;
    DEVICE_INPUT(dev_routingbits_associatedlines_t, RoutingBitsConfiguration::AssociatedLines)
    dev_routingbits_associatedlines;
    DEVICE_INPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    DEVICE_INPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    DEVICE_OUTPUT(dev_routingbits_t, unsigned) dev_routingbits;
    HOST_OUTPUT(host_routingbits_t, unsigned) host_routingbits;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void routingbits_writer(Parameters, const RoutingBitsConfiguration::RoutingBits* dev_routingbits_conf);

  __host__ void get_line_names(Parameters);

  struct routingbits_writer_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };
} // namespace routingbits_writer
