/*****************************************************************************\
* (c) Copyright 2018-2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include <algorithm>
#include <regsort_kernels.h>

namespace SegSort {
#ifndef TARGET_DEVICE_CPU
  template<typename KeyType>
  __global__ void global_sort(
    unsigned* bins,
    unsigned n_segments,
    const KeyType* keys,
    const unsigned* seg_offsets,
    unsigned* permutations)
  {
    for (unsigned s = blockIdx.x * blockDim.y + threadIdx.y; s < n_segments; s += gridDim.x * blockDim.y) {
      unsigned seg = bins[s];

      const auto start = seg_offsets[seg];
      const auto size = seg_offsets[seg + 1] - seg_offsets[seg];

      for (unsigned i = threadIdx.x; i < size; i += blockDim.x) {
        const auto key0 = keys[start + i];

        unsigned position = 0;
        for (unsigned j = 0; j < size; ++j) {
          if (i == j) continue;

          const auto key1 = keys[start + j];
          position += key0 > key1 || (key0 == key1 && i < j);
        }

        // permutations[start + i] = start + position;
        permutations[start + position] = start + i;
      }

      // Decrease divergences
      __syncthreads();
    }
  }

  template<typename KeyType>
  __global__ void segsort_dispatch(
    const unsigned* seg_offsets,
    unsigned n_segments,
    unsigned* bins,
    const KeyType* keys,
    unsigned* permutations)
  {
    const auto get_bin = [](unsigned size) {
      if (size <= 1) return 0;
      if (size > 256) return 9;
      return 32 - __clz(size - 1);
    };

    __shared__ unsigned bins_smem[11];
    if (threadIdx.x < 10) {
      bins_smem[threadIdx.x] = 0;
    }

    __syncthreads();
    unsigned bins_reg[10];
#pragma unroll
    for (unsigned i = 0; i < 10; i++)
      bins_reg[i] = 0;
    for (unsigned i = threadIdx.x; i < n_segments; i += blockDim.x) {
      const auto seg_size = seg_offsets[i + 1] - seg_offsets[i];
      if (seg_size > 0) {
        if (seg_size <= 1)
          bins_reg[0]++;
        else if (seg_size <= 2)
          bins_reg[1]++;
        else if (seg_size <= 4)
          bins_reg[2]++;
        else if (seg_size <= 8)
          bins_reg[3]++;
        else if (seg_size <= 16)
          bins_reg[4]++;
        else if (seg_size <= 32)
          bins_reg[5]++;
        else if (seg_size <= 64)
          bins_reg[6]++;
        else if (seg_size <= 128)
          bins_reg[7]++;
        else if (seg_size <= 256)
          bins_reg[8]++;
        else
          bins_reg[9]++;
      }
    }
#pragma unroll
    for (unsigned i = 0; i < 10; i++)
      atomicAdd(&bins_smem[i], bins_reg[i]);

    __syncthreads();
    // Exclusive prefix sum
    if (threadIdx.x == 0) {
      unsigned sum = 0;
#pragma unroll
      for (int bin = 0; bin < 10; bin++) {
        unsigned val = bins_smem[bin];
        bins_smem[bin] = sum;
        sum += val;
        // printf("segment size <= %d : %d (+%d)\n", 1<<bin, bins_smem[bin], val);
      }
      bins_smem[10] = sum;
    }

    __syncthreads();
    // Dispatch segments to bins
    for (unsigned i = threadIdx.x; i < n_segments; i += blockDim.x) {
      const auto seg_size = seg_offsets[i + 1] - seg_offsets[i];
      if (seg_size > 0) {
        unsigned index = atomicAdd(&bins_smem[get_bin(seg_size)], 1);
        bins[index] = i;
      }
    }

    // bins_smem is now off by one:

    __syncthreads();

    // Launch kernels
    if (threadIdx.x == 0) {
      // Bin 1  (1 < size <= 2)
      unsigned n_segs = bins_smem[1] - bins_smem[0];
      if (n_segs > 0) {
        regsort_2_2t_1ept<KeyType><<<dim3((n_segs + 15) / 16), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[0], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 2  (size <= 4)
      n_segs = bins_smem[2] - bins_smem[1];
      if (n_segs > 0) {
        regsort_4_2t_2ept<KeyType><<<dim3((n_segs + 15) / 16), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[1], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 3  (size <= 8)
      n_segs = bins_smem[3] - bins_smem[2];
      if (n_segs > 0) {
        regsort_8_4t_2ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[2], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 4  (size <= 16)
      n_segs = bins_smem[4] - bins_smem[3];
      if (n_segs > 0) {
        regsort_16_4t_4ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[3], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 5  (size <= 32)
      n_segs = bins_smem[5] - bins_smem[4];
      if (n_segs > 0) {
        regsort_32_8t_4ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 2), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[4], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 6 (size <= 64)
      n_segs = bins_smem[6] - bins_smem[5];
      if (n_segs > 0) {
        regsort_64_32t_2ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 8), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[5], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 7 (size <= 128)
      n_segs = bins_smem[7] - bins_smem[6];
      if (n_segs > 0) {
        regsort_128_32t_4ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 8), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[6], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 8 (size <= 256)
      n_segs = bins_smem[8] - bins_smem[7];
      if (n_segs > 0) {
        regsort_256_32t_8ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 8), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[7], n_segs, keys, seg_offsets, permutations);
      }

      // Bin 9 (size > 256)
      n_segs = bins_smem[9] - bins_smem[8];
      if (n_segs > 0) {
        global_sort<KeyType><<<dim3(n_segs), dim3(256), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[8], n_segs, keys, seg_offsets, permutations);
      }
    }
    // Bin 0 (size == 1)
    for (unsigned s = threadIdx.x; s < bins_smem[0]; s += blockDim.x) {
      unsigned seg = bins[s];
      const auto start = seg_offsets[seg];
      permutations[start] = start;
    }
  }
#endif

  template<typename KeyType, typename Alg, typename Args>
  void segsort(
    [[maybe_unused]] const Alg& alg,
    [[maybe_unused]] const Args& arguments,
    [[maybe_unused]] const Allen::Context& context,
    const KeyType* keys,
    const unsigned* seg_offsets,
    unsigned n_segments,
    unsigned* permutations)
  {
#if defined(TARGET_DEVICE_CPU)
    unsigned n_keys = seg_offsets[n_segments];
    for (unsigned i = 0; i < n_keys; i++) {
      permutations[i] = i;
    }
    for (unsigned s = 0; s < n_segments; s++) {
      unsigned start = seg_offsets[s];
      unsigned end = seg_offsets[s + 1];
      std::sort(
        permutations + start, permutations + end, [&](const auto i, const auto j) { return keys[i] < keys[j]; });
    }
#else
    auto dev_bins = arguments.template make_buffer<Allen::Store::Scope::Device, unsigned>(n_segments);
    alg.global_function(segsort_dispatch<KeyType>)(dim3(1), dim3(256), context)(
      seg_offsets, n_segments, dev_bins.data(), keys, permutations);
#endif
  }

#ifndef TARGET_DEVICE_CPU

  template<typename T>
  inline __device__ void swap(T& a, T& b)
  {
    T c = a;
    a = b;
    b = c;
  }

  template<typename KeyType>
  __global__ void global_sort_keys(unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
  {
    for (unsigned s = blockIdx.x; s < n_segments; s += gridDim.x) {
      unsigned seg = bins[s];

      const unsigned start = seg_offsets[seg];
      const unsigned size = seg_offsets[seg + 1] - start;

      __shared__ int isSorted;

      isSorted = 0;
      __syncthreads();

      while (!isSorted) {
        __syncthreads();

        isSorted = 1;

        __syncthreads();
        // Even phase
        for (unsigned i = threadIdx.x; i * 2 + 1 < size; i += blockDim.x) {
          if (keys[start + i * 2] > keys[start + i * 2 + 1]) {
            swap(keys[start + i * 2], keys[start + i * 2 + 1]);
            isSorted = 0;
          }
        }
        __syncthreads();
        // Odd phase
        for (unsigned i = threadIdx.x; i * 2 + 2 < size; i += blockDim.x) {
          if (keys[start + i * 2 + 1] > keys[start + i * 2 + 2]) {
            swap(keys[start + i * 2 + 1], keys[start + i * 2 + 2]);
            isSorted = 0;
          }
        }
        __syncthreads();
      }
    }
  }

  template<typename KeyType>
  __global__ void segsort_keys_dispatch(const unsigned* seg_offsets, unsigned n_segments, unsigned* bins, KeyType* keys)
  {
    const auto get_bin = [](unsigned size) {
      if (size <= 1) return 0;
      if (size > 256) return 9;
      return 32 - __clz(size - 1);
    };

    __shared__ unsigned bins_smem[11];
    if (threadIdx.x < 10) {
      bins_smem[threadIdx.x] = 0;
    }

    __syncthreads();
    // Make bins histos
    unsigned bins_reg[10];
#pragma unroll
    for (unsigned i = 0; i < 10; i++)
      bins_reg[i] = 0;
    for (unsigned i = threadIdx.x; i < n_segments; i += blockDim.x) {
      const auto seg_size = seg_offsets[i + 1] - seg_offsets[i];
      if (seg_size > 0) {
        if (seg_size <= 1)
          bins_reg[0]++;
        else if (seg_size <= 2)
          bins_reg[1]++;
        else if (seg_size <= 4)
          bins_reg[2]++;
        else if (seg_size <= 8)
          bins_reg[3]++;
        else if (seg_size <= 16)
          bins_reg[4]++;
        else if (seg_size <= 32)
          bins_reg[5]++;
        else if (seg_size <= 64)
          bins_reg[6]++;
        else if (seg_size <= 128)
          bins_reg[7]++;
        else if (seg_size <= 256)
          bins_reg[8]++;
        else
          bins_reg[9]++;
      }
    }
#pragma unroll
    for (unsigned i = 0; i < 10; i++)
      atomicAdd(&bins_smem[i], bins_reg[i]);

    __syncthreads();
    // Exclusive prefix sum
    if (threadIdx.x == 0) {
      unsigned sum = 0;
#pragma unroll
      for (int bin = 0; bin < 10; bin++) {
        unsigned val = bins_smem[bin];
        bins_smem[bin] = sum;
        sum += val;
        // printf("segment size <= %d : %d (+%d)\n", 1<<bin, bins_smem[bin], val);
      }
      bins_smem[10] = sum;
    }

    __syncthreads();
    // Dispatch segments to bins
    for (unsigned i = threadIdx.x; i < n_segments; i += blockDim.x) {
      const auto seg_size = seg_offsets[i + 1] - seg_offsets[i];
      if (seg_size > 0) {
        unsigned index = atomicAdd(&bins_smem[get_bin(seg_size)], 1);
        bins[index] = i;
      }
      /*if (seg_size > 0) {
        unsigned index = get_bin(seg_size);
        unsigned active = __activemask();
        unsigned peers = conflict_mask(active, index);
        unsigned count = __popc(peers);
        unsigned rank = __popc(peers & __lanemask_lt());
        unsigned leader = __ffs(peers) - 1;
        if (rank == 0) index = atomicAdd(&bins_smem[index], count);
        index = __shfl_sync(active, index, leader);
        bins[index + rank] = i;
      }*/
    }

    // bins_smem is now off by one:

    __syncthreads();

    // Launch kernels
    if (threadIdx.x == 0) {
      // Bin 1  (1 < size <= 2)
      unsigned n_segs = bins_smem[1] - bins_smem[0];
      if (n_segs > 0) {
        regsort_2_2t_1ept<KeyType><<<dim3((n_segs + 15) / 16), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[0], n_segs, keys, seg_offsets);
      }

      // Bin 2  (size <= 4)
      n_segs = bins_smem[2] - bins_smem[1];
      if (n_segs > 0) {
        regsort_4_2t_2ept<KeyType><<<dim3((n_segs + 15) / 16), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[1], n_segs, keys, seg_offsets);
      }

      // Bin 3  (size <= 8)
      n_segs = bins_smem[3] - bins_smem[2];
      if (n_segs > 0) {
        regsort_8_4t_2ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[2], n_segs, keys, seg_offsets);
      }

      // Bin 4  (size <= 16)
      n_segs = bins_smem[4] - bins_smem[3];
      if (n_segs > 0) {
        regsort_16_4t_4ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[3], n_segs, keys, seg_offsets);
      }

      // Bin 5  (size <= 32)
      n_segs = bins_smem[5] - bins_smem[4];
      if (n_segs > 0) {
        regsort_32_8t_4ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 2), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[4], n_segs, keys, seg_offsets);
      }

      // Bin 6 (size <= 64)
      n_segs = bins_smem[6] - bins_smem[5];
      if (n_segs > 0) {
        regsort_64_32t_2ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 8), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[5], n_segs, keys, seg_offsets);
      }

      // Bin 7 (size <= 128)
      n_segs = bins_smem[7] - bins_smem[6];
      if (n_segs > 0) {
        regsort_128_32t_4ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 8), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[6], n_segs, keys, seg_offsets);
      }

      // Bin 8 (size <= 256)
      n_segs = bins_smem[8] - bins_smem[7];
      if (n_segs > 0) {
        regsort_256_32t_8ept<KeyType><<<dim3((n_segs + 7) / 8), dim3(32 * 8), 0, cudaStreamFireAndForget>>>(
          bins + bins_smem[7], n_segs, keys, seg_offsets);
      }

      // Bin 9 (size > 256)
      n_segs = bins_smem[9] - bins_smem[8];
      if (n_segs > 0) {
        global_sort_keys<KeyType>
          <<<dim3(n_segs), dim3(256), 0, cudaStreamFireAndForget>>>(bins + bins_smem[8], n_segs, keys, seg_offsets);
      }
    }
  }
#endif

  template<typename KeyType, typename Alg, typename Args>
  void segsort_keys(
    [[maybe_unused]] const Alg& alg,
    [[maybe_unused]] const Args& arguments,
    [[maybe_unused]] const Allen::Context& context,
    KeyType* keys,
    const unsigned* seg_offsets,
    unsigned n_segments)
  {
#if defined(TARGET_DEVICE_CPU)
    for (unsigned s = 0; s < n_segments; s++) {
      unsigned start = seg_offsets[s];
      unsigned end = seg_offsets[s + 1];
      std::sort(keys + start, keys + end);
    }
#else
    auto dev_bins = arguments.template make_buffer<Allen::Store::Scope::Device, unsigned>(n_segments);
    alg.global_function(segsort_keys_dispatch<KeyType>)(dim3(1), dim3(256), context)(
      seg_offsets, n_segments, dev_bins.data(), keys);
#endif
  }

  template<typename KeyType>
  __global__ void check_keys_sorted(const unsigned* seg_offsets, unsigned n_segments, const KeyType* keys)
  {
    for (unsigned seg = 0; seg < n_segments; seg++) {
      bool sorted = true;

      unsigned start = seg_offsets[seg];
      unsigned size = seg_offsets[seg + 1] - start;

      for (unsigned i = 1; i < size; i++) {
        if (keys[start + i - 1] > keys[start + i]) {
          sorted = false;
        }
      }
      if (!sorted) {
        printf("Segment %d (start=%d, size=%d) not sorted\n", seg, start, size);
      }
    }
  }
} // namespace SegSort
