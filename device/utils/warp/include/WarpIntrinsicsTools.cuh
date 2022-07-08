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

#endif

} // namespace Allen::warp
