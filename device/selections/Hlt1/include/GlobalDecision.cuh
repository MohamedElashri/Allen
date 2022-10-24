/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "HltDecReport.cuh"
#include "AlgorithmTypes.cuh"

namespace global_decision {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    DEVICE_INPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    DEVICE_OUTPUT(dev_global_decision_t, bool) dev_global_decision;
    HOST_OUTPUT(host_global_decision_t, bool) host_global_decision;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim_x;
  };

  __global__ void global_decision(Parameters);

  struct global_decision_t : public DeviceAlgorithm, Parameters {
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
    Property<block_dim_x_t> m_block_dim_x {this, 32};
  };
} // namespace global_decision
