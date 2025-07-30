/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

namespace Allen::warp {

#if defined(TARGET_DEVICE_CUDA)

  __device__ inline unsigned prefix_sum_and_increase_size(const bool process_element, unsigned& size)
  {
    const auto mask = __ballot_sync(0xFFFFFFFF, process_element);
    const auto address = size + __popc(mask & ~(-(1u << threadIdx.x)));
    size += __popc(mask);
    return address;
  }

  // Perform a single atomicAdd and populate across entire warp
  template<typename T>
  __device__ inline T atomic_add(T* __restrict__ address, const T size)
  {
    T base_insert_index;
    if (threadIdx.x == 0) {
      base_insert_index = atomicAdd(address, size);
    }
    base_insert_index = __shfl_sync(0xFFFFFFFF, base_insert_index, 0);
    return base_insert_index;
  }

  // Perform a single atomicAdd increment and populate across the entire warp
  template<typename T>
  __device__ inline T atomic_increment(T* __restrict__ address)
  {
    unsigned active = __activemask();
    unsigned peers = conflict_mask(active, (unsigned long long) address);
    unsigned count = __popc(peers);
    unsigned rank = __popc(peers & __lanemask_lt());
    T result;
    if (rank == 0) {
      result = atomicAdd(address, count);
    }
    int leader = __ffs(peers) - 1;
    result = __shfl_sync(peers, result, leader) + static_cast<T>(rank);
    return result;
  }

  // Perform opportunistic warp looping
  template<typename T, typename U>
  __device__ inline void opportunistic_loop(const T number_of_iterations, U function)
  {
    // Forcing blockDim.x to be 32 should be a good idea
    // This ensures that block size will be multiple of 32
    assert(blockDim.x == 32 && blockDim.z == 1);

    // shared_counter has to be initialized to number of threads in block
    // this is because we use this number to begin 2nd iteration of our loop
    __shared__ unsigned shared_counter[1];
    if (threadIdx.x == 0 && threadIdx.y == 0) shared_counter[0] = blockDim.x * blockDim.y;

    T index = threadIdx.x + blockDim.x * threadIdx.y;
    while (__any_sync(0xFFFFFFFF, index < number_of_iterations)) {
      if (index < number_of_iterations) {
        function(index);
      }

      if (threadIdx.x == 0) index = atomicAdd(shared_counter, blockDim.x);
      index = __shfl_sync(0xFFFFFFFF, index, 0) + threadIdx.x;
    }
  }

#elif defined(TARGET_DEVICE_HIP)

  __device__ inline uint64_t prefix_sum_and_increase_size(const bool process_element, unsigned& size)
  {
    const auto mask = __ballot(process_element);
    const auto address = size + __popcll(mask & ~(-(1u << threadIdx.x)));
    size += __popcll(mask);
    return address;
  }

  template<typename T>
  __device__ inline T atomic_add(T* __restrict__ address, const T size)
  {
    T base_insert_index;
    if (threadIdx.x == 0) {
      base_insert_index = atomicAdd(address, size);
    }
    base_insert_index = __shfl(base_insert_index, 0);
    return base_insert_index;
  }

  template<typename T>
  __device__ inline T atomic_increment(T* __restrict__ address)
  {
    T result = atomicAdd(address, 1);
    return result;
  }

  template<typename T, typename U>
  __device__ inline void opportunistic_loop(const T number_of_iterations, U function)
  {
    for (T index = threadIdx.x + blockDim.x * threadIdx.y; index < number_of_iterations; index++) {
      function(index);
    }
  }

#elif defined(TARGET_DEVICE_CPU)

  __device__ inline unsigned prefix_sum_and_increase_size(const bool process_element, unsigned& size)
  {
    const auto address = size;
    size += process_element;
    return address;
  }

  template<typename T>
  __device__ inline T atomic_add(T* __restrict__ address, const T size)
  {
    T base_insert_index = address[0];
    address[0] += size;
    return base_insert_index;
  }

  template<typename T>
  __device__ inline T atomic_increment(T* __restrict__ address)
  {
    T result = address[0];
    address[0]++;
    return result;
  }

  template<typename T, typename U>
  __device__ inline void opportunistic_loop(const T number_of_iterations, U function)
  {
    for (T i = 0; i < number_of_iterations; i++) {
      function(i);
    }
  }

#endif

} // namespace Allen::warp
