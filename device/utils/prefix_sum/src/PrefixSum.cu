/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#include "PrefixSum.cuh"

#ifndef TARGET_DEVICE_CPU
namespace PrefixSum {
  constexpr unsigned NUM_BANKS = 32;
  constexpr unsigned LOG_NUM_BANKS = 5;

  __device__ __forceinline__ unsigned CONFLICT_FREE_OFFSET(unsigned n)
  {
    return /*(n) >> NUM_BANKS +*/ (n) >> (2 * LOG_NUM_BANKS);
  }

  __device__ __forceinline__ unsigned CONFLICT_FREE_ACCESS(unsigned n) { return n + CONFLICT_FREE_OFFSET(n); }

  template<unsigned n>
  __device__ void up_sweep(unsigned* data_block)
  {
    unsigned offset = 1;
#pragma unroll
    for (unsigned d = n / 2; d > 0; d /= 2) {
      if (threadIdx.x < d) {
        int ai = CONFLICT_FREE_ACCESS(offset * (2 * threadIdx.x + 1) - 1);
        int bi = CONFLICT_FREE_ACCESS(offset * (2 * threadIdx.x + 2) - 1);
        data_block[bi] += data_block[ai];
      }
      offset *= 2;
      __syncthreads();
    }
  }

  template<unsigned n>
  __device__ void down_sweep(unsigned* data_block)
  {
    unsigned offset = n / 2;
#pragma unroll
    for (unsigned d = 1; d < n; d *= 2) {
      if (threadIdx.x < d) {
        int ai = CONFLICT_FREE_ACCESS(offset * (2 * threadIdx.x + 1) - 1);
        int bi = CONFLICT_FREE_ACCESS(offset * (2 * threadIdx.x + 2) - 1);
        auto t = data_block[bi];
        data_block[bi] += data_block[ai];
        data_block[ai] = t;
      }
      offset /= 2;
      __syncthreads();
    }
  }

  __global__ void prefix_sum_single_block(unsigned* dev_array, const unsigned array_size)
  {
    // Prefix sum of elements in dev_array
    // Using Blelloch scan
    // https://developer.nvidia.com/gpugems/gpugems3/part-vi-gpu-computing/chapter-39-parallel-prefix-sum-scan-cuda

    constexpr unsigned n = 256;
    __shared__ unsigned data_block[n + n / NUM_BANKS];

    /*__syncthreads();
    if (threadIdx.x == 0) {
      for (int i=0; i<64; i++) {
        printf("%d ", dev_array[i]);
      }
      printf("\n\n");
      for (int i=0; i<64; i++) {
        printf("%d ", dev_array[array_size-63+i]);
      }
      printf("\n\n");
    }
    __syncthreads();*/

    unsigned prev_last_elem = 0;
    for (unsigned block = 0; block < (array_size / n); ++block) {
      const unsigned first_elem = block * n;

      // Load elements into shared memory
      data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] = dev_array[first_elem + 2 * threadIdx.x];
      data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] = dev_array[first_elem + 2 * threadIdx.x + 1];

      __syncthreads();

      up_sweep<n>(data_block);

      const unsigned new_last_elem = data_block[CONFLICT_FREE_ACCESS(n - 1)];

      __syncthreads();
      if (threadIdx.x == 0) {
        data_block[CONFLICT_FREE_ACCESS(n - 1)] = 0;
      }
      __syncthreads();

      down_sweep<n>(data_block);

      // Store back elements, add prev_last_elem
      dev_array[first_elem + 2 * threadIdx.x] = data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] + prev_last_elem;
      dev_array[first_elem + 2 * threadIdx.x + 1] =
        data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] + prev_last_elem;
      prev_last_elem += new_last_elem;

      __syncthreads();
    }

    // Last iteration is special because
    // it may contain an unspecified number of elements
    const auto elements_remaining = array_size % n; //& 0x7FF; // % 2048
    if (elements_remaining > 0) {
      const auto first_elem = array_size - elements_remaining;

      // Initialize all elements to zero
      data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] = 0;
      data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] = 0;

      // Load elements
      const auto elem_index = first_elem + 2 * threadIdx.x;
      if (elem_index < array_size) {
        data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] = dev_array[elem_index];
      }
      if ((elem_index + 1) < array_size) {
        data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] = dev_array[elem_index + 1];
      }

      __syncthreads();

      up_sweep<n>(data_block);

      __syncthreads();
      if (threadIdx.x == 0) {
        dev_array[array_size] = prev_last_elem + data_block[CONFLICT_FREE_ACCESS(n - 1)];
        data_block[CONFLICT_FREE_ACCESS(n - 1)] = 0;
      }
      __syncthreads();

      down_sweep<n>(data_block);

      // Store back elements, add prev_last_elem
      if (elem_index < array_size) {
        dev_array[elem_index] = data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] + prev_last_elem;
      }
      if ((elem_index + 1) < array_size) {
        dev_array[elem_index + 1] = data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] + prev_last_elem;
      }
    }
    else {
      // Special case where number of elements is binary
      if (threadIdx.x == 0) {
        dev_array[array_size] = prev_last_elem;
      }
    }

    /*__syncthreads();
    if (threadIdx.x == 0) {
      for (int i=0; i<64; i++) {
        printf("%d ", dev_array[i]);
      }
      printf("\n\n");
      for (int i=0; i<64; i++) {
        printf("%d ", dev_array[array_size-63+i]);
      }
      printf("\n\n");
    }*/
  }

  __global__ void prefix_sum_reduce(unsigned* dev_array, unsigned* dev_auxiliary_array, const unsigned /*array_size*/)
  {
    constexpr unsigned n = 256; // x4
    __shared__ unsigned data_block[n + n / NUM_BANKS];

    /*__syncthreads();
    if (threadIdx.x == 0 && blockIdx.x == 0) {
      for (int i=0; i<16; i++) {
        printf("%d ", dev_array[i]);
      }
      printf("\n\n");
    }
    __syncthreads();*/

    // Initialize all elements to zero
    data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] = 0;
    data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] = 0;

    // Load elements
    const auto elem_index = blockIdx.x * n + 2 * threadIdx.x;

    uint4 elem1 = ((uint4*) dev_array)[elem_index];
    uint4 elem2 = ((uint4*) dev_array)[elem_index + 1];

    elem1.y += elem1.x;
    elem1.z += elem1.y;
    elem1.w += elem1.z;

    elem2.y += elem2.x;
    elem2.z += elem2.y;
    elem2.w += elem2.z;

    data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] = elem1.w;
    data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] = elem2.w; //*/

    /*data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)] = dev_array[elem_index];
    data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)] = dev_array[elem_index + 1];//*/

    __syncthreads();

    up_sweep<n>(data_block);

    __syncthreads();
    if (threadIdx.x == 0) {
      dev_auxiliary_array[blockIdx.x] = data_block[CONFLICT_FREE_ACCESS(n - 1)];
      data_block[CONFLICT_FREE_ACCESS(n - 1)] = 0;
    }
    __syncthreads();

    down_sweep<n>(data_block);

    // Store back elements
    uint32_t sum1 = data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)];
    elem1.w = sum1 + elem1.z;
    elem1.z = sum1 + elem1.y;
    elem1.y = sum1 + elem1.x;
    elem1.x = sum1;

    uint32_t sum2 = data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)];
    elem2.w = sum2 + elem2.z;
    elem2.z = sum2 + elem2.y;
    elem2.y = sum2 + elem2.x;
    elem2.x = sum2;

    ((uint4*) dev_array)[elem_index] = elem1;
    ((uint4*) dev_array)[elem_index + 1] = elem2; //*/

    /*dev_array[elem_index] = data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x)];
    dev_array[elem_index + 1] = data_block[CONFLICT_FREE_ACCESS(2 * threadIdx.x + 1)];//*/

    /*__syncthreads();
    if (threadIdx.x == 0 && blockIdx.x == 0) {
      for (int i=0; i<16; i++) {
        printf("%d ", dev_array[i]);
      }
      printf("\n\n");
    }
    __syncthreads();*/
  }

  __global__ void prefix_sum_scan(unsigned* dev_array, unsigned* dev_auxiliary_array, const unsigned array_size)
  {
    // Note: The first block is already correctly populated.
    //       Start on the second block.
    const unsigned element = (blockIdx.x + 1) * blockDim.x + threadIdx.x;

    if (element < array_size) {
      const unsigned cluster_offset = dev_auxiliary_array[blockIdx.x + 1];
      dev_array[element] += cluster_offset;
    }
  }
} // namespace PrefixSum
#endif