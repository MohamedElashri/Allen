/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "HostAlgorithm.cuh"

namespace host_prefix_sum {
  struct Parameters {
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
    DEVICE_INPUT(dev_input_buffer_t, unsigned) dev_input_buffer;
    DEVICE_OUTPUT(dev_output_buffer_t, unsigned) dev_output_buffer;
  };

  /**
   * @brief Implementation of prefix sum.
   */
  void host_prefix_sum_impl(
    unsigned* host_prefix_sum_buffer,
    const size_t input_number_of_elements,
    unsigned* host_total_sum_holder = nullptr);

  /**
   * @brief An algorithm that performs the prefix sum on the CPU.
   */
  void host_prefix_sum(
    unsigned* host_prefix_sum_buffer,
    size_t& host_allocated_prefix_sum_space,
    const size_t dev_input_buffer_size,
    const size_t dev_output_buffer_size,
    const Allen::Context& context);

  struct host_prefix_sum_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;
  };
} // namespace host_prefix_sum
