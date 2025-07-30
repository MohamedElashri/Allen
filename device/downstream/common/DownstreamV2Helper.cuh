/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

namespace Downstream::Helpers::details {
  __device__ __host__ inline int lower_bound(float2 arr[], int start, int end, float target)
  {
    int left = start, right = end;
    while (left < right) {
      int mid = left + (right - left) / 2;
      if (arr[mid].x < target) {
        left = mid + 1;
      }
      else {
        right = mid;
      }
    }
    return left;
  }

  __device__ __host__ inline int linear_upper_bound(float2 arr[], int start, int end, float target)
  {
    for (int i = start; i < end; ++i) {
      if (arr[i].x > target) {
        return i;
      }
    }
    return end;
  }
} // namespace Downstream::Helpers::details

namespace Downstream::Helpers {
  template<typename KeyType>
  struct BestSelector {
  private:
    KeyType best_key;
    float best_val = std::numeric_limits<float>::infinity();

  public:
    __device__ __host__ void add(float val, KeyType key)
    {
      if (fabsf(val) < fabsf(best_val)) {
        best_val = val;
        best_key = key;
      }
    }
    __device__ __host__ bool exist() { return std::isfinite(best_val); }
    __device__ __host__ auto& best() { return best_key; }

    __device__ __host__ auto& value() { return best_val; }
  };

  template<typename KeyType>
  struct Best2Selector {
  private:
    KeyType m_best_n_key[2];
    float m_best_n_val[2] = {std::numeric_limits<float>::infinity(), std::numeric_limits<float>::infinity()};

  public:
    __device__ __host__ void add(float val, KeyType key)
    {
      if (!std::isfinite(m_best_n_val[0])) {
        m_best_n_key[0] = key;
        m_best_n_val[0] = val;
        return;
      }

      if (!std::isfinite(m_best_n_val[1])) {
        m_best_n_key[1] = key;
        m_best_n_val[1] = val;
        return;
      }

      if (fabsf(m_best_n_val[0]) > fabsf(val)) {
        m_best_n_key[0] = key;
        m_best_n_val[0] = val;
        return;
      }

      if (fabsf(m_best_n_val[1]) > fabsf(val)) {
        m_best_n_key[1] = key;
        m_best_n_val[1] = val;
        return;
      }
    }
    __device__ __host__ bool exist() { return std::isfinite(m_best_n_val[0]); }
    __device__ __host__ auto& size() { return std::isfinite(m_best_n_val[0]) + std::isfinite(m_best_n_val[1]); }
    __device__ __host__ auto& get(unsigned i) { return m_best_n_key[i]; }

    __device__ __host__ auto& value(unsigned i) { return m_best_n_val[i]; }

    __device__ __host__ auto valid(unsigned i) { return std::isfinite(m_best_n_val[i]); }
  };

  template<unsigned N, typename KeyType>
  struct BestNSelector {
  private:
    unsigned m_size = 0;
    int m_worst = -1;
    KeyType m_best_n_key[N];
    float m_best_n_val[N];

  public:
    __device__ __host__ auto update_worst()
    {
      m_worst = 0;
      for (unsigned idx = 1; idx < m_size; idx++) {
        if (fabsf(m_best_n_val[idx]) > fabsf(m_best_n_val[m_worst])) {
          m_worst = idx;
        }
      }
    }
    __device__ __host__ void add(float val, KeyType key)
    {
      if (m_size < N) {
        m_best_n_key[m_size] = key;
        m_best_n_val[m_size] = val;
        m_size++;
        if (m_size == N) update_worst();
      }
      else {
        if (fabsf(m_best_n_val[m_worst]) > fabsf(val)) {
          m_best_n_key[m_worst] = key;
          m_best_n_val[m_worst] = val;
          update_worst();
        }
      }
    }
    __device__ __host__ bool exist() { return m_size > 0; }
    __device__ __host__ auto size() const { return m_size; }
    __device__ __host__ auto& get(unsigned i) { return m_best_n_key[i]; }

    __device__ __host__ auto& value(unsigned i) { return m_best_n_val[i]; }
  };

  __host__ __device__ __forceinline__ unsigned get_local_sector_idx(
    const uint16_t* selected_offsets,
    const unsigned hit_idx)
  {
    // Fetch sector idx
    unsigned sector_idx = 0;
#if defined(__clang__) or defined(__NVCC__)
#pragma unroll
#elif defined(__GNUC__)
#pragma GCC unroll 16
#endif
    for (unsigned i = 0; i < 16; i++) {
      sector_idx += (hit_idx >= selected_offsets[i]);
    }
    return sector_idx;
  }
} // namespace Downstream::Helpers