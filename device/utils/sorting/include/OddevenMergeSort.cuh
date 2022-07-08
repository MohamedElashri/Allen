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

template<bool sync_mode>
struct iteration_mode {
  __device__ static inline void sync()
  {
    if constexpr (sync_mode == false) {
      __syncwarp();
    }
    else {
      __syncthreads();
    }
  }

  // __device__ static inline unsigned for_assignment()
  // {
  //   if constexpr (invocation_type == 0) {
  //     return threadIdx.x;
  //   }
  //   else {
  //     return threadIdx.x * blockDim.y + threadIdx.y;
  //   }
  // }

  // __device__ static inline unsigned for_next_it()
  // {
  //   if constexpr (invocation_type == 0) {
  //     return blockDim.x;
  //   }
  //   else {
  //     return blockDim.x * blockDim.y;
  //   }
  // }
};

template<bool sync_mode, typename T>
__device__ inline void oddeven_merge_sort(T* __restrict__ a, const unsigned size)
{
  int t = ceilf(log2f(size));
  int p = 1 << (t - 1);

  while (p > 0) {
    int q = 1 << (t - 1);
    int r = 0;
    int d = p;

    while (d > 0) {
      iteration_mode<sync_mode>::sync();

      for (int i = (int) threadIdx.x; i < (int) size - d; i += blockDim.x) {
        if ((i & p) == r) {
          if (a[i] > a[i + d]) {
            const auto temp = a[i];
            a[i] = a[i + d];
            a[i + d] = temp;
          }
        }
      }

      iteration_mode<sync_mode>::sync();

      d = q - p;
      q /= 2;
      r = p;
    }
    p /= 2;
  }
}
