#pragma once

#include "CudaCommon.h"

/**
 * @brief An algorithm that performs the prefix sum on the CPU.
 */
void cpu_prefix_sum(
  uint* host_prefix_sum_buffer,
  size_t& host_allocated_prefix_sum_space,
  uint* dev_prefix_sum_offset,
  const size_t dev_prefix_sum_size,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event,
  uint* host_total_sum_holder = nullptr);

/**
 * @brief Implementation of prefix sum without memcpys.
 */
void cpu_prefix_sum_impl(
  uint* host_prefix_sum_buffer,
  const size_t dev_prefix_sum_size,
  uint* host_total_sum_holder = nullptr);
