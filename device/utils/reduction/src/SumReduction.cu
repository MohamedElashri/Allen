/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "SumReduction.cuh"

namespace SumReduction {

  template<typename T>
  __global__ void parallel_sum_reduction(const T* dev_input_buffer, const unsigned* dev_offsets, T* dev_output_buffer)
  {
    const unsigned event_number = blockIdx.x;
    const unsigned offset = dev_offsets[event_number];
    const unsigned n_elements = dev_offsets[event_number + 1] - offset;
    const T* input_buffer = dev_input_buffer + offset;
    T* sum = dev_output_buffer + event_number;

#ifdef TARGET_DEVICE_CPU
    constexpr unsigned block_size = 1;
    constexpr unsigned warp_size = 1;
#else
    constexpr unsigned block_size = 256; // NOTE: Must match blockDim.x
    constexpr unsigned warp_size = 32;   // NOTE: Must match warpSize
#endif

    // Accumulate elements from global memory in registers
    T local_sum = 0;
    T c = 0; // Kahan sum
    const unsigned r = n_elements % 2;
    for (unsigned i = threadIdx.x * 2; i < n_elements - r; i += 2 * block_size) {
      T y = (input_buffer[i] + input_buffer[i + 1]) - c;
      T t = local_sum + y;
      c = (t - local_sum) - y;
      local_sum = t;
    }

    // Accumulate elements from each warp in shared memory
    constexpr unsigned smem_size = block_size / warp_size;
    __shared__ T shared_data[smem_size];
#ifndef TARGET_DEVICE_CPU
    constexpr unsigned FULL_MASK = 0xffffffff;
    c = 0; // Kahan sum
    for (unsigned offset = warp_size / 2; offset > 0; offset /= 2) {
      T y = __shfl_down_sync(FULL_MASK, local_sum, offset) - c;
      T t = local_sum + y;
      c = (t - local_sum) - y;
      local_sum = t;
    }
#endif

    if (threadIdx.x % warp_size == 0) {
      shared_data[threadIdx.x / warp_size] = local_sum;
    }
    __syncthreads();

    // Accumulate elements from shared memory and return result to global memory
    if (threadIdx.x == 0) {
      T tmp_sum = 0;
      c = 0; // Kahan sum
      for (unsigned i = 0; i < smem_size; i++) {
        T y = shared_data[i] - c;
        T t = tmp_sum + y;
        c = (t - tmp_sum) - y;
        tmp_sum = t;
      }
      *sum = tmp_sum + r * input_buffer[n_elements - 1];
    }
  }

  template __global__ void
  parallel_sum_reduction<float>(const float* dev_input_buffer, const unsigned* dev_offsets, float* dev_output_buffer);

  template __global__ void parallel_sum_reduction<unsigned>(
    const unsigned* dev_input_buffer,
    const unsigned* dev_offsets,
    unsigned* dev_output_buffer);
} // namespace SumReduction
