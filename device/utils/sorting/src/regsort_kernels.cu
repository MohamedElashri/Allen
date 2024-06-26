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

// *** Auto-generated file do not edit *** //

#include <regsort_exch.h>
#include <regsort_kernels.h>

#ifndef TARGET_DEVICE_CPU

// Sorts for size <= 2:

// 2 = 2 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_2_2t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter(rg_k0, rg_v0, 0x1, bit0);

    if (tid * 1 + 0 < size) permutations[start + tid * 1 + 0] = start + rg_v0;
  }
}

template __global__ void regsort_2_2t_1ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_2_2t_1ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_2_2t_1ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 2 = 2 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_2_2t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter_keys(rg_k0, 0x1, bit0);

    if (tid * 1 + 0 < size) keys[start + tid * 1 + 0] = rg_k0;
  }
}

template __global__ void
regsort_2_2t_1ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_2_2t_1ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_2_2t_1ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 4:

// 4 = 2 threads x 2 elements per thread
template<typename KeyType>
__global__ void regsort_4_2t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);

    if (tid * 2 + 0 < size) permutations[start + tid * 2 + 0] = start + rg_v0;
    if (tid * 2 + 1 < size) permutations[start + tid * 2 + 1] = start + rg_v1;
  }
}

template __global__ void regsort_4_2t_2ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_4_2t_2ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_4_2t_2ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 4 = 2 threads x 2 elements per thread
template<typename KeyType>
__global__ void regsort_4_2t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);

    if (tid * 2 + 0 < size) keys[start + tid * 2 + 0] = rg_k0;
    if (tid * 2 + 1 < size) keys[start + tid * 2 + 1] = rg_k1;
  }
}

template __global__ void
regsort_4_2t_2ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_4_2t_2ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_4_2t_2ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 4 = 4 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_4_4t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x3, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);

    if (tid * 1 + 0 < size) permutations[start + tid * 1 + 0] = start + rg_v0;
  }
}

template __global__ void regsort_4_4t_1ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_4_4t_1ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_4_4t_1ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 4 = 4 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_4_4t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x3, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);

    if (tid * 1 + 0 < size) keys[start + tid * 1 + 0] = rg_k0;
  }
}

template __global__ void
regsort_4_4t_1ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_4_4t_1ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_4_4t_1ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 8:

// 8 = 2 threads x 4 elements per thread
template<typename KeyType>
__global__ void regsort_8_2t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_v2 = tid + 4;
    rg_v3 = tid + 6;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);

    if (tid * 4 + 0 < size) permutations[start + tid * 4 + 0] = start + rg_v0;
    if (tid * 4 + 1 < size) permutations[start + tid * 4 + 1] = start + rg_v1;
    if (tid * 4 + 2 < size) permutations[start + tid * 4 + 2] = start + rg_v2;
    if (tid * 4 + 3 < size) permutations[start + tid * 4 + 3] = start + rg_v3;
  }
}

template __global__ void regsort_8_2t_4ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_8_2t_4ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_8_2t_4ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 8 = 2 threads x 4 elements per thread
template<typename KeyType>
__global__ void regsort_8_2t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_v2 = tid + 4;
    rg_v3 = tid + 6;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);

    if (tid * 4 + 0 < size) keys[start + tid * 4 + 0] = rg_k0;
    if (tid * 4 + 1 < size) keys[start + tid * 4 + 1] = rg_k1;
    if (tid * 4 + 2 < size) keys[start + tid * 4 + 2] = rg_k2;
    if (tid * 4 + 3 < size) keys[start + tid * 4 + 3] = rg_k3;
  }
}

template __global__ void
regsort_8_2t_4ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_8_2t_4ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_8_2t_4ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 8 = 4 threads x 2 elements per thread
template<typename KeyType>
__global__ void regsort_8_4t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);

    if (tid * 2 + 0 < size) permutations[start + tid * 2 + 0] = start + rg_v0;
    if (tid * 2 + 1 < size) permutations[start + tid * 2 + 1] = start + rg_v1;
  }
}

template __global__ void regsort_8_4t_2ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_8_4t_2ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_8_4t_2ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 8 = 4 threads x 2 elements per thread
template<typename KeyType>
__global__ void regsort_8_4t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);

    if (tid * 2 + 0 < size) keys[start + tid * 2 + 0] = rg_k0;
    if (tid * 2 + 1 < size) keys[start + tid * 2 + 1] = rg_k1;
  }
}

template __global__ void
regsort_8_4t_2ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_8_4t_2ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_8_4t_2ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 8 = 8 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_8_8t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x3, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x7, bit2);
    exch_inter(rg_k0, rg_v0, 0x2, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);

    if (tid * 1 + 0 < size) permutations[start + tid * 1 + 0] = start + rg_v0;
  }
}

template __global__ void regsort_8_8t_1ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_8_8t_1ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_8_8t_1ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 8 = 8 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_8_8t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x3, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x7, bit2);
    exch_inter_keys(rg_k0, 0x2, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);

    if (tid * 1 + 0 < size) keys[start + tid * 1 + 0] = rg_k0;
  }
}

template __global__ void
regsort_8_8t_1ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_8_8t_1ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_8_8t_1ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 16:

// 16 = 2 threads x 8 elements per thread
template<typename KeyType>
__global__ void regsort_16_2t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_v2 = tid + 4;
    rg_v3 = tid + 6;
    rg_v4 = tid + 8;
    rg_v5 = tid + 10;
    rg_v6 = tid + 12;
    rg_v7 = tid + 14;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);

    if (tid * 8 + 0 < size) permutations[start + tid * 8 + 0] = start + rg_v0;
    if (tid * 8 + 1 < size) permutations[start + tid * 8 + 1] = start + rg_v1;
    if (tid * 8 + 2 < size) permutations[start + tid * 8 + 2] = start + rg_v2;
    if (tid * 8 + 3 < size) permutations[start + tid * 8 + 3] = start + rg_v3;
    if (tid * 8 + 4 < size) permutations[start + tid * 8 + 4] = start + rg_v4;
    if (tid * 8 + 5 < size) permutations[start + tid * 8 + 5] = start + rg_v5;
    if (tid * 8 + 6 < size) permutations[start + tid * 8 + 6] = start + rg_v6;
    if (tid * 8 + 7 < size) permutations[start + tid * 8 + 7] = start + rg_v7;
  }
}

template __global__ void regsort_16_2t_8ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_2t_8ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_2t_8ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 16 = 2 threads x 8 elements per thread
template<typename KeyType>
__global__ void
regsort_16_2t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_v2 = tid + 4;
    rg_v3 = tid + 6;
    rg_v4 = tid + 8;
    rg_v5 = tid + 10;
    rg_v6 = tid + 12;
    rg_v7 = tid + 14;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);

    if (tid * 8 + 0 < size) keys[start + tid * 8 + 0] = rg_k0;
    if (tid * 8 + 1 < size) keys[start + tid * 8 + 1] = rg_k1;
    if (tid * 8 + 2 < size) keys[start + tid * 8 + 2] = rg_k2;
    if (tid * 8 + 3 < size) keys[start + tid * 8 + 3] = rg_k3;
    if (tid * 8 + 4 < size) keys[start + tid * 8 + 4] = rg_k4;
    if (tid * 8 + 5 < size) keys[start + tid * 8 + 5] = rg_k5;
    if (tid * 8 + 6 < size) keys[start + tid * 8 + 6] = rg_k6;
    if (tid * 8 + 7 < size) keys[start + tid * 8 + 7] = rg_k7;
  }
}

template __global__ void
regsort_16_2t_8ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_2t_8ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_2t_8ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 16 = 4 threads x 4 elements per thread
template<typename KeyType>
__global__ void regsort_16_4t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_v2 = tid + 8;
    rg_v3 = tid + 12;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);

    if (tid * 4 + 0 < size) permutations[start + tid * 4 + 0] = start + rg_v0;
    if (tid * 4 + 1 < size) permutations[start + tid * 4 + 1] = start + rg_v1;
    if (tid * 4 + 2 < size) permutations[start + tid * 4 + 2] = start + rg_v2;
    if (tid * 4 + 3 < size) permutations[start + tid * 4 + 3] = start + rg_v3;
  }
}

template __global__ void regsort_16_4t_4ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_4t_4ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_4t_4ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 16 = 4 threads x 4 elements per thread
template<typename KeyType>
__global__ void
regsort_16_4t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_v2 = tid + 8;
    rg_v3 = tid + 12;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);

    if (tid * 4 + 0 < size) keys[start + tid * 4 + 0] = rg_k0;
    if (tid * 4 + 1 < size) keys[start + tid * 4 + 1] = rg_k1;
    if (tid * 4 + 2 < size) keys[start + tid * 4 + 2] = rg_k2;
    if (tid * 4 + 3 < size) keys[start + tid * 4 + 3] = rg_k3;
  }
}

template __global__ void
regsort_16_4t_4ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_4t_4ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_4t_4ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 16 = 8 threads x 2 elements per thread
template<typename KeyType>
__global__ void regsort_16_8t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x7, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);

    if (tid * 2 + 0 < size) permutations[start + tid * 2 + 0] = start + rg_v0;
    if (tid * 2 + 1 < size) permutations[start + tid * 2 + 1] = start + rg_v1;
  }
}

template __global__ void regsort_16_8t_2ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_8t_2ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_8t_2ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 16 = 8 threads x 2 elements per thread
template<typename KeyType>
__global__ void
regsort_16_8t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);

    if (tid * 2 + 0 < size) keys[start + tid * 2 + 0] = rg_k0;
    if (tid * 2 + 1 < size) keys[start + tid * 2 + 1] = rg_k1;
  }
}

template __global__ void
regsort_16_8t_2ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_8t_2ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_8t_2ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 16 = 16 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_16_16t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x3, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x7, bit2);
    exch_inter(rg_k0, rg_v0, 0x2, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0xf, bit3);
    exch_inter(rg_k0, rg_v0, 0x4, bit2);
    exch_inter(rg_k0, rg_v0, 0x2, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);

    if (tid * 1 + 0 < size) permutations[start + tid * 1 + 0] = start + rg_v0;
  }
}

template __global__ void regsort_16_16t_1ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_16t_1ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_16_16t_1ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 16 = 16 threads x 1 elements per thread
template<typename KeyType>
__global__ void
regsort_16_16t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x3, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x7, bit2);
    exch_inter_keys(rg_k0, 0x2, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0xf, bit3);
    exch_inter_keys(rg_k0, 0x4, bit2);
    exch_inter_keys(rg_k0, 0x2, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);

    if (tid * 1 + 0 < size) keys[start + tid * 1 + 0] = rg_k0;
  }
}

template __global__ void
regsort_16_16t_1ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_16t_1ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_16_16t_1ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 32:

// 32 = 2 threads x 16 elements per thread
template<typename KeyType>
__global__ void regsort_32_2t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_v2 = tid + 4;
    rg_v3 = tid + 6;
    rg_v4 = tid + 8;
    rg_v5 = tid + 10;
    rg_v6 = tid + 12;
    rg_v7 = tid + 14;
    rg_v8 = tid + 16;
    rg_v9 = tid + 18;
    rg_v10 = tid + 20;
    rg_v11 = tid + 22;
    rg_v12 = tid + 24;
    rg_v13 = tid + 26;
    rg_v14 = tid + 28;
    rg_v15 = tid + 30;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11, rg_v8, rg_v11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10, rg_v9, rg_v10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15, rg_v12, rg_v15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14, rg_v13, rg_v14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15, rg_v8, rg_v15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14, rg_v9, rg_v14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13, rg_v10, rg_v13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12, rg_v11, rg_v12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15, rg_v0, rg_v15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14, rg_v1, rg_v14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13, rg_v2, rg_v13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12, rg_v3, rg_v12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11, rg_v4, rg_v11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10, rg_v5, rg_v10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9, rg_v6, rg_v9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8, rg_v7, rg_v8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);

    if (tid * 16 + 0 < size) permutations[start + tid * 16 + 0] = start + rg_v0;
    if (tid * 16 + 1 < size) permutations[start + tid * 16 + 1] = start + rg_v1;
    if (tid * 16 + 2 < size) permutations[start + tid * 16 + 2] = start + rg_v2;
    if (tid * 16 + 3 < size) permutations[start + tid * 16 + 3] = start + rg_v3;
    if (tid * 16 + 4 < size) permutations[start + tid * 16 + 4] = start + rg_v4;
    if (tid * 16 + 5 < size) permutations[start + tid * 16 + 5] = start + rg_v5;
    if (tid * 16 + 6 < size) permutations[start + tid * 16 + 6] = start + rg_v6;
    if (tid * 16 + 7 < size) permutations[start + tid * 16 + 7] = start + rg_v7;
    if (tid * 16 + 8 < size) permutations[start + tid * 16 + 8] = start + rg_v8;
    if (tid * 16 + 9 < size) permutations[start + tid * 16 + 9] = start + rg_v9;
    if (tid * 16 + 10 < size) permutations[start + tid * 16 + 10] = start + rg_v10;
    if (tid * 16 + 11 < size) permutations[start + tid * 16 + 11] = start + rg_v11;
    if (tid * 16 + 12 < size) permutations[start + tid * 16 + 12] = start + rg_v12;
    if (tid * 16 + 13 < size) permutations[start + tid * 16 + 13] = start + rg_v13;
    if (tid * 16 + 14 < size) permutations[start + tid * 16 + 14] = start + rg_v14;
    if (tid * 16 + 15 < size) permutations[start + tid * 16 + 15] = start + rg_v15;
  }
}

template __global__ void regsort_32_2t_16ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_2t_16ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_2t_16ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 32 = 2 threads x 16 elements per thread
template<typename KeyType>
__global__ void
regsort_32_2t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 2;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 2;
  unsigned tid = threadIdx.x & 1;
  const bool bit0 = (tid >> 0) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 2;
    rg_v2 = tid + 4;
    rg_v3 = tid + 6;
    rg_v4 = tid + 8;
    rg_v5 = tid + 10;
    rg_v6 = tid + 12;
    rg_v7 = tid + 14;
    rg_v8 = tid + 16;
    rg_v9 = tid + 18;
    rg_v10 = tid + 20;
    rg_v11 = tid + 22;
    rg_v12 = tid + 24;
    rg_v13 = tid + 26;
    rg_v14 = tid + 28;
    rg_v15 = tid + 30;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);

    if (tid * 16 + 0 < size) keys[start + tid * 16 + 0] = rg_k0;
    if (tid * 16 + 1 < size) keys[start + tid * 16 + 1] = rg_k1;
    if (tid * 16 + 2 < size) keys[start + tid * 16 + 2] = rg_k2;
    if (tid * 16 + 3 < size) keys[start + tid * 16 + 3] = rg_k3;
    if (tid * 16 + 4 < size) keys[start + tid * 16 + 4] = rg_k4;
    if (tid * 16 + 5 < size) keys[start + tid * 16 + 5] = rg_k5;
    if (tid * 16 + 6 < size) keys[start + tid * 16 + 6] = rg_k6;
    if (tid * 16 + 7 < size) keys[start + tid * 16 + 7] = rg_k7;
    if (tid * 16 + 8 < size) keys[start + tid * 16 + 8] = rg_k8;
    if (tid * 16 + 9 < size) keys[start + tid * 16 + 9] = rg_k9;
    if (tid * 16 + 10 < size) keys[start + tid * 16 + 10] = rg_k10;
    if (tid * 16 + 11 < size) keys[start + tid * 16 + 11] = rg_k11;
    if (tid * 16 + 12 < size) keys[start + tid * 16 + 12] = rg_k12;
    if (tid * 16 + 13 < size) keys[start + tid * 16 + 13] = rg_k13;
    if (tid * 16 + 14 < size) keys[start + tid * 16 + 14] = rg_k14;
    if (tid * 16 + 15 < size) keys[start + tid * 16 + 15] = rg_k15;
  }
}

template __global__ void
regsort_32_2t_16ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_2t_16ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_2t_16ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 32 = 4 threads x 8 elements per thread
template<typename KeyType>
__global__ void regsort_32_4t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_v2 = tid + 8;
    rg_v3 = tid + 12;
    rg_v4 = tid + 16;
    rg_v5 = tid + 20;
    rg_v6 = tid + 24;
    rg_v7 = tid + 28;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);

    if (tid * 8 + 0 < size) permutations[start + tid * 8 + 0] = start + rg_v0;
    if (tid * 8 + 1 < size) permutations[start + tid * 8 + 1] = start + rg_v1;
    if (tid * 8 + 2 < size) permutations[start + tid * 8 + 2] = start + rg_v2;
    if (tid * 8 + 3 < size) permutations[start + tid * 8 + 3] = start + rg_v3;
    if (tid * 8 + 4 < size) permutations[start + tid * 8 + 4] = start + rg_v4;
    if (tid * 8 + 5 < size) permutations[start + tid * 8 + 5] = start + rg_v5;
    if (tid * 8 + 6 < size) permutations[start + tid * 8 + 6] = start + rg_v6;
    if (tid * 8 + 7 < size) permutations[start + tid * 8 + 7] = start + rg_v7;
  }
}

template __global__ void regsort_32_4t_8ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_4t_8ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_4t_8ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 32 = 4 threads x 8 elements per thread
template<typename KeyType>
__global__ void
regsort_32_4t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_v2 = tid + 8;
    rg_v3 = tid + 12;
    rg_v4 = tid + 16;
    rg_v5 = tid + 20;
    rg_v6 = tid + 24;
    rg_v7 = tid + 28;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);

    if (tid * 8 + 0 < size) keys[start + tid * 8 + 0] = rg_k0;
    if (tid * 8 + 1 < size) keys[start + tid * 8 + 1] = rg_k1;
    if (tid * 8 + 2 < size) keys[start + tid * 8 + 2] = rg_k2;
    if (tid * 8 + 3 < size) keys[start + tid * 8 + 3] = rg_k3;
    if (tid * 8 + 4 < size) keys[start + tid * 8 + 4] = rg_k4;
    if (tid * 8 + 5 < size) keys[start + tid * 8 + 5] = rg_k5;
    if (tid * 8 + 6 < size) keys[start + tid * 8 + 6] = rg_k6;
    if (tid * 8 + 7 < size) keys[start + tid * 8 + 7] = rg_k7;
  }
}

template __global__ void
regsort_32_4t_8ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_4t_8ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_4t_8ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 32 = 8 threads x 4 elements per thread
template<typename KeyType>
__global__ void regsort_32_8t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_v2 = tid + 16;
    rg_v3 = tid + 24;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x7, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);

    if (tid * 4 + 0 < size) permutations[start + tid * 4 + 0] = start + rg_v0;
    if (tid * 4 + 1 < size) permutations[start + tid * 4 + 1] = start + rg_v1;
    if (tid * 4 + 2 < size) permutations[start + tid * 4 + 2] = start + rg_v2;
    if (tid * 4 + 3 < size) permutations[start + tid * 4 + 3] = start + rg_v3;
  }
}

template __global__ void regsort_32_8t_4ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_8t_4ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_8t_4ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 32 = 8 threads x 4 elements per thread
template<typename KeyType>
__global__ void
regsort_32_8t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_v2 = tid + 16;
    rg_v3 = tid + 24;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);

    if (tid * 4 + 0 < size) keys[start + tid * 4 + 0] = rg_k0;
    if (tid * 4 + 1 < size) keys[start + tid * 4 + 1] = rg_k1;
    if (tid * 4 + 2 < size) keys[start + tid * 4 + 2] = rg_k2;
    if (tid * 4 + 3 < size) keys[start + tid * 4 + 3] = rg_k3;
  }
}

template __global__ void
regsort_32_8t_4ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_8t_4ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_8t_4ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 32 = 16 threads x 2 elements per thread
template<typename KeyType>
__global__ void regsort_32_16t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x7, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0xf, bit3);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x4, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);

    if (tid * 2 + 0 < size) permutations[start + tid * 2 + 0] = start + rg_v0;
    if (tid * 2 + 1 < size) permutations[start + tid * 2 + 1] = start + rg_v1;
  }
}

template __global__ void regsort_32_16t_2ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_16t_2ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_16t_2ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 32 = 16 threads x 2 elements per thread
template<typename KeyType>
__global__ void
regsort_32_16t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0xf, bit3);
    exch_paral_keys(rg_k0, rg_k1, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);

    if (tid * 2 + 0 < size) keys[start + tid * 2 + 0] = rg_k0;
    if (tid * 2 + 1 < size) keys[start + tid * 2 + 1] = rg_k1;
  }
}

template __global__ void
regsort_32_16t_2ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_16t_2ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_16t_2ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 32 = 32 threads x 1 elements per thread
template<typename KeyType>
__global__ void regsort_32_32t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x3, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x7, bit2);
    exch_inter(rg_k0, rg_v0, 0x2, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0xf, bit3);
    exch_inter(rg_k0, rg_v0, 0x4, bit2);
    exch_inter(rg_k0, rg_v0, 0x2, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);
    exch_inter(rg_k0, rg_v0, 0x1f, bit4);
    exch_inter(rg_k0, rg_v0, 0x8, bit3);
    exch_inter(rg_k0, rg_v0, 0x4, bit2);
    exch_inter(rg_k0, rg_v0, 0x2, bit1);
    exch_inter(rg_k0, rg_v0, 0x1, bit0);

    if (tid * 1 + 0 < size) permutations[start + tid * 1 + 0] = start + rg_v0;
  }
}

template __global__ void regsort_32_32t_1ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_32t_1ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_32_32t_1ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 32 = 32 threads x 1 elements per thread
template<typename KeyType>
__global__ void
regsort_32_32t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0;
  unsigned rg_v0;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();

    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x3, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x7, bit2);
    exch_inter_keys(rg_k0, 0x2, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0xf, bit3);
    exch_inter_keys(rg_k0, 0x4, bit2);
    exch_inter_keys(rg_k0, 0x2, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);
    exch_inter_keys(rg_k0, 0x1f, bit4);
    exch_inter_keys(rg_k0, 0x8, bit3);
    exch_inter_keys(rg_k0, 0x4, bit2);
    exch_inter_keys(rg_k0, 0x2, bit1);
    exch_inter_keys(rg_k0, 0x1, bit0);

    if (tid * 1 + 0 < size) keys[start + tid * 1 + 0] = rg_k0;
  }
}

template __global__ void
regsort_32_32t_1ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_32t_1ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_32_32t_1ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 64:

// 64 = 4 threads x 16 elements per thread
template<typename KeyType>
__global__ void regsort_64_4t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_v2 = tid + 8;
    rg_v3 = tid + 12;
    rg_v4 = tid + 16;
    rg_v5 = tid + 20;
    rg_v6 = tid + 24;
    rg_v7 = tid + 28;
    rg_v8 = tid + 32;
    rg_v9 = tid + 36;
    rg_v10 = tid + 40;
    rg_v11 = tid + 44;
    rg_v12 = tid + 48;
    rg_v13 = tid + 52;
    rg_v14 = tid + 56;
    rg_v15 = tid + 60;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11, rg_v8, rg_v11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10, rg_v9, rg_v10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15, rg_v12, rg_v15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14, rg_v13, rg_v14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15, rg_v8, rg_v15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14, rg_v9, rg_v14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13, rg_v10, rg_v13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12, rg_v11, rg_v12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15, rg_v0, rg_v15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14, rg_v1, rg_v14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13, rg_v2, rg_v13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12, rg_v3, rg_v12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11, rg_v4, rg_v11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10, rg_v5, rg_v10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9, rg_v6, rg_v9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8, rg_v7, rg_v8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);

    if (tid * 16 + 0 < size) permutations[start + tid * 16 + 0] = start + rg_v0;
    if (tid * 16 + 1 < size) permutations[start + tid * 16 + 1] = start + rg_v1;
    if (tid * 16 + 2 < size) permutations[start + tid * 16 + 2] = start + rg_v2;
    if (tid * 16 + 3 < size) permutations[start + tid * 16 + 3] = start + rg_v3;
    if (tid * 16 + 4 < size) permutations[start + tid * 16 + 4] = start + rg_v4;
    if (tid * 16 + 5 < size) permutations[start + tid * 16 + 5] = start + rg_v5;
    if (tid * 16 + 6 < size) permutations[start + tid * 16 + 6] = start + rg_v6;
    if (tid * 16 + 7 < size) permutations[start + tid * 16 + 7] = start + rg_v7;
    if (tid * 16 + 8 < size) permutations[start + tid * 16 + 8] = start + rg_v8;
    if (tid * 16 + 9 < size) permutations[start + tid * 16 + 9] = start + rg_v9;
    if (tid * 16 + 10 < size) permutations[start + tid * 16 + 10] = start + rg_v10;
    if (tid * 16 + 11 < size) permutations[start + tid * 16 + 11] = start + rg_v11;
    if (tid * 16 + 12 < size) permutations[start + tid * 16 + 12] = start + rg_v12;
    if (tid * 16 + 13 < size) permutations[start + tid * 16 + 13] = start + rg_v13;
    if (tid * 16 + 14 < size) permutations[start + tid * 16 + 14] = start + rg_v14;
    if (tid * 16 + 15 < size) permutations[start + tid * 16 + 15] = start + rg_v15;
  }
}

template __global__ void regsort_64_4t_16ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_4t_16ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_4t_16ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 64 = 4 threads x 16 elements per thread
template<typename KeyType>
__global__ void
regsort_64_4t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 4;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 4;
  unsigned tid = threadIdx.x & 3;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 4;
    rg_v2 = tid + 8;
    rg_v3 = tid + 12;
    rg_v4 = tid + 16;
    rg_v5 = tid + 20;
    rg_v6 = tid + 24;
    rg_v7 = tid + 28;
    rg_v8 = tid + 32;
    rg_v9 = tid + 36;
    rg_v10 = tid + 40;
    rg_v11 = tid + 44;
    rg_v12 = tid + 48;
    rg_v13 = tid + 52;
    rg_v14 = tid + 56;
    rg_v15 = tid + 60;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x3,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);

    if (tid * 16 + 0 < size) keys[start + tid * 16 + 0] = rg_k0;
    if (tid * 16 + 1 < size) keys[start + tid * 16 + 1] = rg_k1;
    if (tid * 16 + 2 < size) keys[start + tid * 16 + 2] = rg_k2;
    if (tid * 16 + 3 < size) keys[start + tid * 16 + 3] = rg_k3;
    if (tid * 16 + 4 < size) keys[start + tid * 16 + 4] = rg_k4;
    if (tid * 16 + 5 < size) keys[start + tid * 16 + 5] = rg_k5;
    if (tid * 16 + 6 < size) keys[start + tid * 16 + 6] = rg_k6;
    if (tid * 16 + 7 < size) keys[start + tid * 16 + 7] = rg_k7;
    if (tid * 16 + 8 < size) keys[start + tid * 16 + 8] = rg_k8;
    if (tid * 16 + 9 < size) keys[start + tid * 16 + 9] = rg_k9;
    if (tid * 16 + 10 < size) keys[start + tid * 16 + 10] = rg_k10;
    if (tid * 16 + 11 < size) keys[start + tid * 16 + 11] = rg_k11;
    if (tid * 16 + 12 < size) keys[start + tid * 16 + 12] = rg_k12;
    if (tid * 16 + 13 < size) keys[start + tid * 16 + 13] = rg_k13;
    if (tid * 16 + 14 < size) keys[start + tid * 16 + 14] = rg_k14;
    if (tid * 16 + 15 < size) keys[start + tid * 16 + 15] = rg_k15;
  }
}

template __global__ void
regsort_64_4t_16ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_4t_16ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_4t_16ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 64 = 8 threads x 8 elements per thread
template<typename KeyType>
__global__ void regsort_64_8t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_v2 = tid + 16;
    rg_v3 = tid + 24;
    rg_v4 = tid + 32;
    rg_v5 = tid + 40;
    rg_v6 = tid + 48;
    rg_v7 = tid + 56;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x7,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);

    if (tid * 8 + 0 < size) permutations[start + tid * 8 + 0] = start + rg_v0;
    if (tid * 8 + 1 < size) permutations[start + tid * 8 + 1] = start + rg_v1;
    if (tid * 8 + 2 < size) permutations[start + tid * 8 + 2] = start + rg_v2;
    if (tid * 8 + 3 < size) permutations[start + tid * 8 + 3] = start + rg_v3;
    if (tid * 8 + 4 < size) permutations[start + tid * 8 + 4] = start + rg_v4;
    if (tid * 8 + 5 < size) permutations[start + tid * 8 + 5] = start + rg_v5;
    if (tid * 8 + 6 < size) permutations[start + tid * 8 + 6] = start + rg_v6;
    if (tid * 8 + 7 < size) permutations[start + tid * 8 + 7] = start + rg_v7;
  }
}

template __global__ void regsort_64_8t_8ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_8t_8ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_8t_8ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 64 = 8 threads x 8 elements per thread
template<typename KeyType>
__global__ void
regsort_64_8t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_v2 = tid + 16;
    rg_v3 = tid + 24;
    rg_v4 = tid + 32;
    rg_v5 = tid + 40;
    rg_v6 = tid + 48;
    rg_v7 = tid + 56;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);

    if (tid * 8 + 0 < size) keys[start + tid * 8 + 0] = rg_k0;
    if (tid * 8 + 1 < size) keys[start + tid * 8 + 1] = rg_k1;
    if (tid * 8 + 2 < size) keys[start + tid * 8 + 2] = rg_k2;
    if (tid * 8 + 3 < size) keys[start + tid * 8 + 3] = rg_k3;
    if (tid * 8 + 4 < size) keys[start + tid * 8 + 4] = rg_k4;
    if (tid * 8 + 5 < size) keys[start + tid * 8 + 5] = rg_k5;
    if (tid * 8 + 6 < size) keys[start + tid * 8 + 6] = rg_k6;
    if (tid * 8 + 7 < size) keys[start + tid * 8 + 7] = rg_k7;
  }
}

template __global__ void
regsort_64_8t_8ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_8t_8ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_8t_8ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 64 = 16 threads x 4 elements per thread
template<typename KeyType>
__global__ void regsort_64_16t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_v2 = tid + 32;
    rg_v3 = tid + 48;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x7, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0xf, bit3);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x4, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);

    if (tid * 4 + 0 < size) permutations[start + tid * 4 + 0] = start + rg_v0;
    if (tid * 4 + 1 < size) permutations[start + tid * 4 + 1] = start + rg_v1;
    if (tid * 4 + 2 < size) permutations[start + tid * 4 + 2] = start + rg_v2;
    if (tid * 4 + 3 < size) permutations[start + tid * 4 + 3] = start + rg_v3;
  }
}

template __global__ void regsort_64_16t_4ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_16t_4ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_16t_4ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 64 = 16 threads x 4 elements per thread
template<typename KeyType>
__global__ void
regsort_64_16t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_v2 = tid + 32;
    rg_v3 = tid + 48;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0xf, bit3);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);

    if (tid * 4 + 0 < size) keys[start + tid * 4 + 0] = rg_k0;
    if (tid * 4 + 1 < size) keys[start + tid * 4 + 1] = rg_k1;
    if (tid * 4 + 2 < size) keys[start + tid * 4 + 2] = rg_k2;
    if (tid * 4 + 3 < size) keys[start + tid * 4 + 3] = rg_k3;
  }
}

template __global__ void
regsort_64_16t_4ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_16t_4ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_16t_4ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 64 = 32 threads x 2 elements per thread
template<typename KeyType>
__global__ void regsort_64_32t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x7, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0xf, bit3);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x4, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, 0x1f, bit4);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x8, bit3);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x4, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);

    if (tid * 2 + 0 < size) permutations[start + tid * 2 + 0] = start + rg_v0;
    if (tid * 2 + 1 < size) permutations[start + tid * 2 + 1] = start + rg_v1;
  }
}

template __global__ void regsort_64_32t_2ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_32t_2ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_64_32t_2ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 64 = 32 threads x 2 elements per thread
template<typename KeyType>
__global__ void
regsort_64_32t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1;
  unsigned rg_v0, rg_v1;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0xf, bit3);
    exch_paral_keys(rg_k0, rg_k1, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    exch_inter_keys(rg_k0, rg_k1, 0x1f, bit4);
    exch_paral_keys(rg_k0, rg_k1, 0x8, bit3);
    exch_paral_keys(rg_k0, rg_k1, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);

    if (tid * 2 + 0 < size) keys[start + tid * 2 + 0] = rg_k0;
    if (tid * 2 + 1 < size) keys[start + tid * 2 + 1] = rg_k1;
  }
}

template __global__ void
regsort_64_32t_2ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_32t_2ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_64_32t_2ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 128:

// 128 = 8 threads x 16 elements per thread
template<typename KeyType>
__global__ void regsort_128_8t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_v2 = tid + 16;
    rg_v3 = tid + 24;
    rg_v4 = tid + 32;
    rg_v5 = tid + 40;
    rg_v6 = tid + 48;
    rg_v7 = tid + 56;
    rg_v8 = tid + 64;
    rg_v9 = tid + 72;
    rg_v10 = tid + 80;
    rg_v11 = tid + 88;
    rg_v12 = tid + 96;
    rg_v13 = tid + 104;
    rg_v14 = tid + 112;
    rg_v15 = tid + 120;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11, rg_v8, rg_v11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10, rg_v9, rg_v10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15, rg_v12, rg_v15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14, rg_v13, rg_v14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15, rg_v8, rg_v15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14, rg_v9, rg_v14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13, rg_v10, rg_v13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12, rg_v11, rg_v12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15, rg_v0, rg_v15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14, rg_v1, rg_v14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13, rg_v2, rg_v13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12, rg_v3, rg_v12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11, rg_v4, rg_v11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10, rg_v5, rg_v10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9, rg_v6, rg_v9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8, rg_v7, rg_v8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x7,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);

    if (tid * 16 + 0 < size) permutations[start + tid * 16 + 0] = start + rg_v0;
    if (tid * 16 + 1 < size) permutations[start + tid * 16 + 1] = start + rg_v1;
    if (tid * 16 + 2 < size) permutations[start + tid * 16 + 2] = start + rg_v2;
    if (tid * 16 + 3 < size) permutations[start + tid * 16 + 3] = start + rg_v3;
    if (tid * 16 + 4 < size) permutations[start + tid * 16 + 4] = start + rg_v4;
    if (tid * 16 + 5 < size) permutations[start + tid * 16 + 5] = start + rg_v5;
    if (tid * 16 + 6 < size) permutations[start + tid * 16 + 6] = start + rg_v6;
    if (tid * 16 + 7 < size) permutations[start + tid * 16 + 7] = start + rg_v7;
    if (tid * 16 + 8 < size) permutations[start + tid * 16 + 8] = start + rg_v8;
    if (tid * 16 + 9 < size) permutations[start + tid * 16 + 9] = start + rg_v9;
    if (tid * 16 + 10 < size) permutations[start + tid * 16 + 10] = start + rg_v10;
    if (tid * 16 + 11 < size) permutations[start + tid * 16 + 11] = start + rg_v11;
    if (tid * 16 + 12 < size) permutations[start + tid * 16 + 12] = start + rg_v12;
    if (tid * 16 + 13 < size) permutations[start + tid * 16 + 13] = start + rg_v13;
    if (tid * 16 + 14 < size) permutations[start + tid * 16 + 14] = start + rg_v14;
    if (tid * 16 + 15 < size) permutations[start + tid * 16 + 15] = start + rg_v15;
  }
}

template __global__ void regsort_128_8t_16ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_128_8t_16ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_128_8t_16ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 128 = 8 threads x 16 elements per thread
template<typename KeyType>
__global__ void
regsort_128_8t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 8;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 8;
  unsigned tid = threadIdx.x & 7;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 8;
    rg_v2 = tid + 16;
    rg_v3 = tid + 24;
    rg_v4 = tid + 32;
    rg_v5 = tid + 40;
    rg_v6 = tid + 48;
    rg_v7 = tid + 56;
    rg_v8 = tid + 64;
    rg_v9 = tid + 72;
    rg_v10 = tid + 80;
    rg_v11 = tid + 88;
    rg_v12 = tid + 96;
    rg_v13 = tid + 104;
    rg_v14 = tid + 112;
    rg_v15 = tid + 120;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x3,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x7,
      bit2);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x2,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);

    if (tid * 16 + 0 < size) keys[start + tid * 16 + 0] = rg_k0;
    if (tid * 16 + 1 < size) keys[start + tid * 16 + 1] = rg_k1;
    if (tid * 16 + 2 < size) keys[start + tid * 16 + 2] = rg_k2;
    if (tid * 16 + 3 < size) keys[start + tid * 16 + 3] = rg_k3;
    if (tid * 16 + 4 < size) keys[start + tid * 16 + 4] = rg_k4;
    if (tid * 16 + 5 < size) keys[start + tid * 16 + 5] = rg_k5;
    if (tid * 16 + 6 < size) keys[start + tid * 16 + 6] = rg_k6;
    if (tid * 16 + 7 < size) keys[start + tid * 16 + 7] = rg_k7;
    if (tid * 16 + 8 < size) keys[start + tid * 16 + 8] = rg_k8;
    if (tid * 16 + 9 < size) keys[start + tid * 16 + 9] = rg_k9;
    if (tid * 16 + 10 < size) keys[start + tid * 16 + 10] = rg_k10;
    if (tid * 16 + 11 < size) keys[start + tid * 16 + 11] = rg_k11;
    if (tid * 16 + 12 < size) keys[start + tid * 16 + 12] = rg_k12;
    if (tid * 16 + 13 < size) keys[start + tid * 16 + 13] = rg_k13;
    if (tid * 16 + 14 < size) keys[start + tid * 16 + 14] = rg_k14;
    if (tid * 16 + 15 < size) keys[start + tid * 16 + 15] = rg_k15;
  }
}

template __global__ void
regsort_128_8t_16ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_128_8t_16ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_128_8t_16ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 128 = 16 threads x 8 elements per thread
template<typename KeyType>
__global__ void regsort_128_16t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_v2 = tid + 32;
    rg_v3 = tid + 48;
    rg_v4 = tid + 64;
    rg_v5 = tid + 80;
    rg_v6 = tid + 96;
    rg_v7 = tid + 112;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x7,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0xf,
      bit3);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x4,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);

    if (tid * 8 + 0 < size) permutations[start + tid * 8 + 0] = start + rg_v0;
    if (tid * 8 + 1 < size) permutations[start + tid * 8 + 1] = start + rg_v1;
    if (tid * 8 + 2 < size) permutations[start + tid * 8 + 2] = start + rg_v2;
    if (tid * 8 + 3 < size) permutations[start + tid * 8 + 3] = start + rg_v3;
    if (tid * 8 + 4 < size) permutations[start + tid * 8 + 4] = start + rg_v4;
    if (tid * 8 + 5 < size) permutations[start + tid * 8 + 5] = start + rg_v5;
    if (tid * 8 + 6 < size) permutations[start + tid * 8 + 6] = start + rg_v6;
    if (tid * 8 + 7 < size) permutations[start + tid * 8 + 7] = start + rg_v7;
  }
}

template __global__ void regsort_128_16t_8ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_128_16t_8ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_128_16t_8ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 128 = 16 threads x 8 elements per thread
template<typename KeyType>
__global__ void
regsort_128_16t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_v2 = tid + 32;
    rg_v3 = tid + 48;
    rg_v4 = tid + 64;
    rg_v5 = tid + 80;
    rg_v6 = tid + 96;
    rg_v7 = tid + 112;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0xf, bit3);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);

    if (tid * 8 + 0 < size) keys[start + tid * 8 + 0] = rg_k0;
    if (tid * 8 + 1 < size) keys[start + tid * 8 + 1] = rg_k1;
    if (tid * 8 + 2 < size) keys[start + tid * 8 + 2] = rg_k2;
    if (tid * 8 + 3 < size) keys[start + tid * 8 + 3] = rg_k3;
    if (tid * 8 + 4 < size) keys[start + tid * 8 + 4] = rg_k4;
    if (tid * 8 + 5 < size) keys[start + tid * 8 + 5] = rg_k5;
    if (tid * 8 + 6 < size) keys[start + tid * 8 + 6] = rg_k6;
    if (tid * 8 + 7 < size) keys[start + tid * 8 + 7] = rg_k7;
  }
}

template __global__ void
regsort_128_16t_8ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_128_16t_8ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_128_16t_8ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 128 = 32 threads x 4 elements per thread
template<typename KeyType>
__global__ void regsort_128_32t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_v2 = tid + 64;
    rg_v3 = tid + 96;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x3, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x7, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0xf, bit3);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x4, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    exch_inter(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1f, bit4);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x8, bit3);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x4, bit2);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x2, bit1);
    exch_paral(rg_k0, rg_v0, rg_k1, rg_v1, rg_k2, rg_v2, rg_k3, rg_v3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);

    if (tid * 4 + 0 < size) permutations[start + tid * 4 + 0] = start + rg_v0;
    if (tid * 4 + 1 < size) permutations[start + tid * 4 + 1] = start + rg_v1;
    if (tid * 4 + 2 < size) permutations[start + tid * 4 + 2] = start + rg_v2;
    if (tid * 4 + 3 < size) permutations[start + tid * 4 + 3] = start + rg_v3;
  }
}

template __global__ void regsort_128_32t_4ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_128_32t_4ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_128_32t_4ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 128 = 32 threads x 4 elements per thread
template<typename KeyType>
__global__ void
regsort_128_32t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_v2 = tid + 64;
    rg_v3 = tid + 96;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0xf, bit3);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1f, bit4);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x8, bit3);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);

    if (tid * 4 + 0 < size) keys[start + tid * 4 + 0] = rg_k0;
    if (tid * 4 + 1 < size) keys[start + tid * 4 + 1] = rg_k1;
    if (tid * 4 + 2 < size) keys[start + tid * 4 + 2] = rg_k2;
    if (tid * 4 + 3 < size) keys[start + tid * 4 + 3] = rg_k3;
  }
}

template __global__ void
regsort_128_32t_4ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_128_32t_4ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_128_32t_4ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 256:

// 256 = 16 threads x 16 elements per thread
template<typename KeyType>
__global__ void regsort_256_16t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_v2 = tid + 32;
    rg_v3 = tid + 48;
    rg_v4 = tid + 64;
    rg_v5 = tid + 80;
    rg_v6 = tid + 96;
    rg_v7 = tid + 112;
    rg_v8 = tid + 128;
    rg_v9 = tid + 144;
    rg_v10 = tid + 160;
    rg_v11 = tid + 176;
    rg_v12 = tid + 192;
    rg_v13 = tid + 208;
    rg_v14 = tid + 224;
    rg_v15 = tid + 240;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11, rg_v8, rg_v11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10, rg_v9, rg_v10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15, rg_v12, rg_v15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14, rg_v13, rg_v14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15, rg_v8, rg_v15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14, rg_v9, rg_v14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13, rg_v10, rg_v13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12, rg_v11, rg_v12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15, rg_v0, rg_v15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14, rg_v1, rg_v14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13, rg_v2, rg_v13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12, rg_v3, rg_v12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11, rg_v4, rg_v11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10, rg_v5, rg_v10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9, rg_v6, rg_v9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8, rg_v7, rg_v8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x7,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0xf,
      bit3);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x4,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);

    if (tid * 16 + 0 < size) permutations[start + tid * 16 + 0] = start + rg_v0;
    if (tid * 16 + 1 < size) permutations[start + tid * 16 + 1] = start + rg_v1;
    if (tid * 16 + 2 < size) permutations[start + tid * 16 + 2] = start + rg_v2;
    if (tid * 16 + 3 < size) permutations[start + tid * 16 + 3] = start + rg_v3;
    if (tid * 16 + 4 < size) permutations[start + tid * 16 + 4] = start + rg_v4;
    if (tid * 16 + 5 < size) permutations[start + tid * 16 + 5] = start + rg_v5;
    if (tid * 16 + 6 < size) permutations[start + tid * 16 + 6] = start + rg_v6;
    if (tid * 16 + 7 < size) permutations[start + tid * 16 + 7] = start + rg_v7;
    if (tid * 16 + 8 < size) permutations[start + tid * 16 + 8] = start + rg_v8;
    if (tid * 16 + 9 < size) permutations[start + tid * 16 + 9] = start + rg_v9;
    if (tid * 16 + 10 < size) permutations[start + tid * 16 + 10] = start + rg_v10;
    if (tid * 16 + 11 < size) permutations[start + tid * 16 + 11] = start + rg_v11;
    if (tid * 16 + 12 < size) permutations[start + tid * 16 + 12] = start + rg_v12;
    if (tid * 16 + 13 < size) permutations[start + tid * 16 + 13] = start + rg_v13;
    if (tid * 16 + 14 < size) permutations[start + tid * 16 + 14] = start + rg_v14;
    if (tid * 16 + 15 < size) permutations[start + tid * 16 + 15] = start + rg_v15;
  }
}

template __global__ void regsort_256_16t_16ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_256_16t_16ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_256_16t_16ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 256 = 16 threads x 16 elements per thread
template<typename KeyType>
__global__ void
regsort_256_16t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 16;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 16;
  unsigned tid = threadIdx.x & 15;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 16;
    rg_v2 = tid + 32;
    rg_v3 = tid + 48;
    rg_v4 = tid + 64;
    rg_v5 = tid + 80;
    rg_v6 = tid + 96;
    rg_v7 = tid + 112;
    rg_v8 = tid + 128;
    rg_v9 = tid + 144;
    rg_v10 = tid + 160;
    rg_v11 = tid + 176;
    rg_v12 = tid + 192;
    rg_v13 = tid + 208;
    rg_v14 = tid + 224;
    rg_v15 = tid + 240;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x3,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x7,
      bit2);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x2,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0xf,
      bit3);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x4,
      bit2);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x2,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);

    if (tid * 16 + 0 < size) keys[start + tid * 16 + 0] = rg_k0;
    if (tid * 16 + 1 < size) keys[start + tid * 16 + 1] = rg_k1;
    if (tid * 16 + 2 < size) keys[start + tid * 16 + 2] = rg_k2;
    if (tid * 16 + 3 < size) keys[start + tid * 16 + 3] = rg_k3;
    if (tid * 16 + 4 < size) keys[start + tid * 16 + 4] = rg_k4;
    if (tid * 16 + 5 < size) keys[start + tid * 16 + 5] = rg_k5;
    if (tid * 16 + 6 < size) keys[start + tid * 16 + 6] = rg_k6;
    if (tid * 16 + 7 < size) keys[start + tid * 16 + 7] = rg_k7;
    if (tid * 16 + 8 < size) keys[start + tid * 16 + 8] = rg_k8;
    if (tid * 16 + 9 < size) keys[start + tid * 16 + 9] = rg_k9;
    if (tid * 16 + 10 < size) keys[start + tid * 16 + 10] = rg_k10;
    if (tid * 16 + 11 < size) keys[start + tid * 16 + 11] = rg_k11;
    if (tid * 16 + 12 < size) keys[start + tid * 16 + 12] = rg_k12;
    if (tid * 16 + 13 < size) keys[start + tid * 16 + 13] = rg_k13;
    if (tid * 16 + 14 < size) keys[start + tid * 16 + 14] = rg_k14;
    if (tid * 16 + 15 < size) keys[start + tid * 16 + 15] = rg_k15;
  }
}

template __global__ void
regsort_256_16t_16ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_256_16t_16ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_256_16t_16ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// 256 = 32 threads x 8 elements per thread
template<typename KeyType>
__global__ void regsort_256_32t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_v2 = tid + 64;
    rg_v3 = tid + 96;
    rg_v4 = tid + 128;
    rg_v5 = tid + 160;
    rg_v6 = tid + 192;
    rg_v7 = tid + 224;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x7,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0xf,
      bit3);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x4,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1f,
      bit4);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x8,
      bit3);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x4,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);

    if (tid * 8 + 0 < size) permutations[start + tid * 8 + 0] = start + rg_v0;
    if (tid * 8 + 1 < size) permutations[start + tid * 8 + 1] = start + rg_v1;
    if (tid * 8 + 2 < size) permutations[start + tid * 8 + 2] = start + rg_v2;
    if (tid * 8 + 3 < size) permutations[start + tid * 8 + 3] = start + rg_v3;
    if (tid * 8 + 4 < size) permutations[start + tid * 8 + 4] = start + rg_v4;
    if (tid * 8 + 5 < size) permutations[start + tid * 8 + 5] = start + rg_v5;
    if (tid * 8 + 6 < size) permutations[start + tid * 8 + 6] = start + rg_v6;
    if (tid * 8 + 7 < size) permutations[start + tid * 8 + 7] = start + rg_v7;
  }
}

template __global__ void regsort_256_32t_8ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_256_32t_8ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_256_32t_8ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 256 = 32 threads x 8 elements per thread
template<typename KeyType>
__global__ void
regsort_256_32t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_v2 = tid + 64;
    rg_v3 = tid + 96;
    rg_v4 = tid + 128;
    rg_v5 = tid + 160;
    rg_v6 = tid + 192;
    rg_v7 = tid + 224;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x3, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x7, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0xf, bit3);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    exch_inter_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1f, bit4);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x8, bit3);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x4, bit2);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x2, bit1);
    exch_paral_keys(rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, 0x1, bit0);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);

    if (tid * 8 + 0 < size) keys[start + tid * 8 + 0] = rg_k0;
    if (tid * 8 + 1 < size) keys[start + tid * 8 + 1] = rg_k1;
    if (tid * 8 + 2 < size) keys[start + tid * 8 + 2] = rg_k2;
    if (tid * 8 + 3 < size) keys[start + tid * 8 + 3] = rg_k3;
    if (tid * 8 + 4 < size) keys[start + tid * 8 + 4] = rg_k4;
    if (tid * 8 + 5 < size) keys[start + tid * 8 + 5] = rg_k5;
    if (tid * 8 + 6 < size) keys[start + tid * 8 + 6] = rg_k6;
    if (tid * 8 + 7 < size) keys[start + tid * 8 + 7] = rg_k7;
  }
}

template __global__ void
regsort_256_32t_8ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_256_32t_8ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_256_32t_8ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

// Sorts for size <= 512:

// 512 = 32 threads x 16 elements per thread
template<typename KeyType>
__global__ void regsort_512_32t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_v2 = tid + 64;
    rg_v3 = tid + 96;
    rg_v4 = tid + 128;
    rg_v5 = tid + 160;
    rg_v6 = tid + 192;
    rg_v7 = tid + 224;
    rg_v8 = tid + 256;
    rg_v9 = tid + 288;
    rg_v10 = tid + 320;
    rg_v11 = tid + 352;
    rg_v12 = tid + 384;
    rg_v13 = tid + 416;
    rg_v14 = tid + 448;
    rg_v15 = tid + 480;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3, rg_v0, rg_v3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2, rg_v1, rg_v2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7, rg_v4, rg_v7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6, rg_v5, rg_v6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11, rg_v8, rg_v11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10, rg_v9, rg_v10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15, rg_v12, rg_v15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14, rg_v13, rg_v14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7, rg_v0, rg_v7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6, rg_v1, rg_v6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5, rg_v2, rg_v5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4, rg_v3, rg_v4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15, rg_v8, rg_v15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14, rg_v9, rg_v14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13, rg_v10, rg_v13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12, rg_v11, rg_v12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15, rg_v0, rg_v15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14, rg_v1, rg_v14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13, rg_v2, rg_v13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12, rg_v3, rg_v12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11, rg_v4, rg_v11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10, rg_v5, rg_v10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9, rg_v6, rg_v9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8, rg_v7, rg_v8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x3,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x7,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0xf,
      bit3);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x4,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);
    exch_inter(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1f,
      bit4);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x8,
      bit3);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x4,
      bit2);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x2,
      bit1);
    exch_paral(
      rg_k0,
      rg_v0,
      rg_k1,
      rg_v1,
      rg_k2,
      rg_v2,
      rg_k3,
      rg_v3,
      rg_k4,
      rg_v4,
      rg_k5,
      rg_v5,
      rg_k6,
      rg_v6,
      rg_k7,
      rg_v7,
      rg_k8,
      rg_v8,
      rg_k9,
      rg_v9,
      rg_k10,
      rg_v10,
      rg_k11,
      rg_v11,
      rg_k12,
      rg_v12,
      rg_k13,
      rg_v13,
      rg_k14,
      rg_v14,
      rg_k15,
      rg_v15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8, rg_v0, rg_v8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9, rg_v1, rg_v9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10, rg_v2, rg_v10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11, rg_v3, rg_v11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12, rg_v4, rg_v12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13, rg_v5, rg_v13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14, rg_v6, rg_v14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15, rg_v7, rg_v15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4, rg_v0, rg_v4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5, rg_v1, rg_v5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6, rg_v2, rg_v6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7, rg_v3, rg_v7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12, rg_v8, rg_v12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13, rg_v9, rg_v13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14, rg_v10, rg_v14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15, rg_v11, rg_v15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2, rg_v0, rg_v2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3, rg_v1, rg_v3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6, rg_v4, rg_v6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7, rg_v5, rg_v7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10, rg_v8, rg_v10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11, rg_v9, rg_v11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14, rg_v12, rg_v14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15, rg_v13, rg_v15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1, rg_v0, rg_v1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3, rg_v2, rg_v3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5, rg_v4, rg_v5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7, rg_v6, rg_v7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9, rg_v8, rg_v9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11, rg_v10, rg_v11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13, rg_v12, rg_v13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15, rg_v14, rg_v15);

    if (tid * 16 + 0 < size) permutations[start + tid * 16 + 0] = start + rg_v0;
    if (tid * 16 + 1 < size) permutations[start + tid * 16 + 1] = start + rg_v1;
    if (tid * 16 + 2 < size) permutations[start + tid * 16 + 2] = start + rg_v2;
    if (tid * 16 + 3 < size) permutations[start + tid * 16 + 3] = start + rg_v3;
    if (tid * 16 + 4 < size) permutations[start + tid * 16 + 4] = start + rg_v4;
    if (tid * 16 + 5 < size) permutations[start + tid * 16 + 5] = start + rg_v5;
    if (tid * 16 + 6 < size) permutations[start + tid * 16 + 6] = start + rg_v6;
    if (tid * 16 + 7 < size) permutations[start + tid * 16 + 7] = start + rg_v7;
    if (tid * 16 + 8 < size) permutations[start + tid * 16 + 8] = start + rg_v8;
    if (tid * 16 + 9 < size) permutations[start + tid * 16 + 9] = start + rg_v9;
    if (tid * 16 + 10 < size) permutations[start + tid * 16 + 10] = start + rg_v10;
    if (tid * 16 + 11 < size) permutations[start + tid * 16 + 11] = start + rg_v11;
    if (tid * 16 + 12 < size) permutations[start + tid * 16 + 12] = start + rg_v12;
    if (tid * 16 + 13 < size) permutations[start + tid * 16 + 13] = start + rg_v13;
    if (tid * 16 + 14 < size) permutations[start + tid * 16 + 14] = start + rg_v14;
    if (tid * 16 + 15 < size) permutations[start + tid * 16 + 15] = start + rg_v15;
  }
}

template __global__ void regsort_512_32t_16ept<uint32_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint32_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_512_32t_16ept<int64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const int64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template __global__ void regsort_512_32t_16ept<uint64_t>(
  const unsigned* bins,
  unsigned n_segments,
  const uint64_t* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);

// 512 = 32 threads x 16 elements per thread
template<typename KeyType>
__global__ void
regsort_512_32t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets)
{
  unsigned step = (gridDim.x * blockDim.x) / 32;
  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
  unsigned tid = threadIdx.x & 31;
  const bool bit0 = (tid >> 0) & 1;
  const bool bit1 = (tid >> 1) & 1;
  const bool bit2 = (tid >> 2) & 1;
  const bool bit3 = (tid >> 3) & 1;
  const bool bit4 = (tid >> 4) & 1;
  KeyType rg_k0, rg_k1, rg_k2, rg_k3, rg_k4, rg_k5, rg_k6, rg_k7, rg_k8, rg_k9, rg_k10, rg_k11, rg_k12, rg_k13, rg_k14,
    rg_k15;
  unsigned rg_v0, rg_v1, rg_v2, rg_v3, rg_v4, rg_v5, rg_v6, rg_v7, rg_v8, rg_v9, rg_v10, rg_v11, rg_v12, rg_v13, rg_v14,
    rg_v15;
  for (unsigned s = first_seg; s < n_segments; s += step) {
    unsigned seg = bins[s];
    const unsigned start = seg_offsets[seg];
    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];

    rg_v0 = tid + 0;
    rg_v1 = tid + 32;
    rg_v2 = tid + 64;
    rg_v3 = tid + 96;
    rg_v4 = tid + 128;
    rg_v5 = tid + 160;
    rg_v6 = tid + 192;
    rg_v7 = tid + 224;
    rg_v8 = tid + 256;
    rg_v9 = tid + 288;
    rg_v10 = tid + 320;
    rg_v11 = tid + 352;
    rg_v12 = tid + 384;
    rg_v13 = tid + 416;
    rg_v14 = tid + 448;
    rg_v15 = tid + 480;
    rg_k0 = (rg_v0 < size) ? keys[start + rg_v0] : std::numeric_limits<KeyType>::max();
    rg_k1 = (rg_v1 < size) ? keys[start + rg_v1] : std::numeric_limits<KeyType>::max();
    rg_k2 = (rg_v2 < size) ? keys[start + rg_v2] : std::numeric_limits<KeyType>::max();
    rg_k3 = (rg_v3 < size) ? keys[start + rg_v3] : std::numeric_limits<KeyType>::max();
    rg_k4 = (rg_v4 < size) ? keys[start + rg_v4] : std::numeric_limits<KeyType>::max();
    rg_k5 = (rg_v5 < size) ? keys[start + rg_v5] : std::numeric_limits<KeyType>::max();
    rg_k6 = (rg_v6 < size) ? keys[start + rg_v6] : std::numeric_limits<KeyType>::max();
    rg_k7 = (rg_v7 < size) ? keys[start + rg_v7] : std::numeric_limits<KeyType>::max();
    rg_k8 = (rg_v8 < size) ? keys[start + rg_v8] : std::numeric_limits<KeyType>::max();
    rg_k9 = (rg_v9 < size) ? keys[start + rg_v9] : std::numeric_limits<KeyType>::max();
    rg_k10 = (rg_v10 < size) ? keys[start + rg_v10] : std::numeric_limits<KeyType>::max();
    rg_k11 = (rg_v11 < size) ? keys[start + rg_v11] : std::numeric_limits<KeyType>::max();
    rg_k12 = (rg_v12 < size) ? keys[start + rg_v12] : std::numeric_limits<KeyType>::max();
    rg_k13 = (rg_v13 < size) ? keys[start + rg_v13] : std::numeric_limits<KeyType>::max();
    rg_k14 = (rg_v14 < size) ? keys[start + rg_v14] : std::numeric_limits<KeyType>::max();
    rg_k15 = (rg_v15 < size) ? keys[start + rg_v15] : std::numeric_limits<KeyType>::max();

    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k3, rg_k0, rg_k3);
    cond_swap_regs(rg_k1 > rg_k2, rg_k1, rg_k2);
    cond_swap_regs(rg_k4 > rg_k7, rg_k4, rg_k7);
    cond_swap_regs(rg_k5 > rg_k6, rg_k5, rg_k6);
    cond_swap_regs(rg_k8 > rg_k11, rg_k8, rg_k11);
    cond_swap_regs(rg_k9 > rg_k10, rg_k9, rg_k10);
    cond_swap_regs(rg_k12 > rg_k15, rg_k12, rg_k15);
    cond_swap_regs(rg_k13 > rg_k14, rg_k13, rg_k14);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k7, rg_k0, rg_k7);
    cond_swap_regs(rg_k1 > rg_k6, rg_k1, rg_k6);
    cond_swap_regs(rg_k2 > rg_k5, rg_k2, rg_k5);
    cond_swap_regs(rg_k3 > rg_k4, rg_k3, rg_k4);
    cond_swap_regs(rg_k8 > rg_k15, rg_k8, rg_k15);
    cond_swap_regs(rg_k9 > rg_k14, rg_k9, rg_k14);
    cond_swap_regs(rg_k10 > rg_k13, rg_k10, rg_k13);
    cond_swap_regs(rg_k11 > rg_k12, rg_k11, rg_k12);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    cond_swap_regs(rg_k0 > rg_k15, rg_k0, rg_k15);
    cond_swap_regs(rg_k1 > rg_k14, rg_k1, rg_k14);
    cond_swap_regs(rg_k2 > rg_k13, rg_k2, rg_k13);
    cond_swap_regs(rg_k3 > rg_k12, rg_k3, rg_k12);
    cond_swap_regs(rg_k4 > rg_k11, rg_k4, rg_k11);
    cond_swap_regs(rg_k5 > rg_k10, rg_k5, rg_k10);
    cond_swap_regs(rg_k6 > rg_k9, rg_k6, rg_k9);
    cond_swap_regs(rg_k7 > rg_k8, rg_k7, rg_k8);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x3,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x7,
      bit2);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x2,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0xf,
      bit3);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x4,
      bit2);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x2,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);
    exch_inter_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1f,
      bit4);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x8,
      bit3);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x4,
      bit2);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x2,
      bit1);
    exch_paral_keys(
      rg_k0,
      rg_k1,
      rg_k2,
      rg_k3,
      rg_k4,
      rg_k5,
      rg_k6,
      rg_k7,
      rg_k8,
      rg_k9,
      rg_k10,
      rg_k11,
      rg_k12,
      rg_k13,
      rg_k14,
      rg_k15,
      0x1,
      bit0);
    cond_swap_regs(rg_k0 > rg_k8, rg_k0, rg_k8);
    cond_swap_regs(rg_k1 > rg_k9, rg_k1, rg_k9);
    cond_swap_regs(rg_k2 > rg_k10, rg_k2, rg_k10);
    cond_swap_regs(rg_k3 > rg_k11, rg_k3, rg_k11);
    cond_swap_regs(rg_k4 > rg_k12, rg_k4, rg_k12);
    cond_swap_regs(rg_k5 > rg_k13, rg_k5, rg_k13);
    cond_swap_regs(rg_k6 > rg_k14, rg_k6, rg_k14);
    cond_swap_regs(rg_k7 > rg_k15, rg_k7, rg_k15);
    cond_swap_regs(rg_k0 > rg_k4, rg_k0, rg_k4);
    cond_swap_regs(rg_k1 > rg_k5, rg_k1, rg_k5);
    cond_swap_regs(rg_k2 > rg_k6, rg_k2, rg_k6);
    cond_swap_regs(rg_k3 > rg_k7, rg_k3, rg_k7);
    cond_swap_regs(rg_k8 > rg_k12, rg_k8, rg_k12);
    cond_swap_regs(rg_k9 > rg_k13, rg_k9, rg_k13);
    cond_swap_regs(rg_k10 > rg_k14, rg_k10, rg_k14);
    cond_swap_regs(rg_k11 > rg_k15, rg_k11, rg_k15);
    cond_swap_regs(rg_k0 > rg_k2, rg_k0, rg_k2);
    cond_swap_regs(rg_k1 > rg_k3, rg_k1, rg_k3);
    cond_swap_regs(rg_k4 > rg_k6, rg_k4, rg_k6);
    cond_swap_regs(rg_k5 > rg_k7, rg_k5, rg_k7);
    cond_swap_regs(rg_k8 > rg_k10, rg_k8, rg_k10);
    cond_swap_regs(rg_k9 > rg_k11, rg_k9, rg_k11);
    cond_swap_regs(rg_k12 > rg_k14, rg_k12, rg_k14);
    cond_swap_regs(rg_k13 > rg_k15, rg_k13, rg_k15);
    cond_swap_regs(rg_k0 > rg_k1, rg_k0, rg_k1);
    cond_swap_regs(rg_k2 > rg_k3, rg_k2, rg_k3);
    cond_swap_regs(rg_k4 > rg_k5, rg_k4, rg_k5);
    cond_swap_regs(rg_k6 > rg_k7, rg_k6, rg_k7);
    cond_swap_regs(rg_k8 > rg_k9, rg_k8, rg_k9);
    cond_swap_regs(rg_k10 > rg_k11, rg_k10, rg_k11);
    cond_swap_regs(rg_k12 > rg_k13, rg_k12, rg_k13);
    cond_swap_regs(rg_k14 > rg_k15, rg_k14, rg_k15);

    if (tid * 16 + 0 < size) keys[start + tid * 16 + 0] = rg_k0;
    if (tid * 16 + 1 < size) keys[start + tid * 16 + 1] = rg_k1;
    if (tid * 16 + 2 < size) keys[start + tid * 16 + 2] = rg_k2;
    if (tid * 16 + 3 < size) keys[start + tid * 16 + 3] = rg_k3;
    if (tid * 16 + 4 < size) keys[start + tid * 16 + 4] = rg_k4;
    if (tid * 16 + 5 < size) keys[start + tid * 16 + 5] = rg_k5;
    if (tid * 16 + 6 < size) keys[start + tid * 16 + 6] = rg_k6;
    if (tid * 16 + 7 < size) keys[start + tid * 16 + 7] = rg_k7;
    if (tid * 16 + 8 < size) keys[start + tid * 16 + 8] = rg_k8;
    if (tid * 16 + 9 < size) keys[start + tid * 16 + 9] = rg_k9;
    if (tid * 16 + 10 < size) keys[start + tid * 16 + 10] = rg_k10;
    if (tid * 16 + 11 < size) keys[start + tid * 16 + 11] = rg_k11;
    if (tid * 16 + 12 < size) keys[start + tid * 16 + 12] = rg_k12;
    if (tid * 16 + 13 < size) keys[start + tid * 16 + 13] = rg_k13;
    if (tid * 16 + 14 < size) keys[start + tid * 16 + 14] = rg_k14;
    if (tid * 16 + 15 < size) keys[start + tid * 16 + 15] = rg_k15;
  }
}

template __global__ void
regsort_512_32t_16ept<uint32_t>(const unsigned* bins, unsigned n_segments, uint32_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_512_32t_16ept<int64_t>(const unsigned* bins, unsigned n_segments, int64_t* keys, const unsigned* seg_offsets);
template __global__ void
regsort_512_32t_16ept<uint64_t>(const unsigned* bins, unsigned n_segments, uint64_t* keys, const unsigned* seg_offsets);

#endif
