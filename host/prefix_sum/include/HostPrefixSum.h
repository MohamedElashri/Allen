#pragma once

#include "CudaCommon.h"
#include "HostAlgorithm.cuh"

namespace host_prefix_sum {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_OUTPUT(host_total_sum_holder_t, uint), host_total_sum_holder),
    (DEVICE_INPUT(dev_input_buffer_t, uint), dev_input_buffer),
    (DEVICE_OUTPUT(dev_output_buffer_t, uint), dev_output_buffer))
  
  /**
   * @brief Implementation of prefix sum.
   */
  void host_prefix_sum_impl(
    uint* host_prefix_sum_buffer,
    const size_t input_number_of_elements,
    uint* host_total_sum_holder = nullptr);

  /**
   * @brief An algorithm that performs the prefix sum on the CPU.
   */
  void host_prefix_sum(
    uint* host_prefix_sum_buffer,
    size_t& host_allocated_prefix_sum_space,
    const size_t dev_input_buffer_size,
    const size_t dev_output_buffer_size,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event,
    Parameters parameters);

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
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const;
  };
} // namespace host_prefix_sum
