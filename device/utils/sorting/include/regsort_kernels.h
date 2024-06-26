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

#pragma once

#ifndef TARGET_DEVICE_CPU

// Sorts for size <= 2:

template<typename KeyType>
__global__ void regsort_2_2t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_2_2t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 4:

template<typename KeyType>
__global__ void regsort_4_2t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_4_2t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_4_4t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_4_4t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 8:

template<typename KeyType>
__global__ void regsort_8_2t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_8_2t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_8_4t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_8_4t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_8_8t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_8_8t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 16:

template<typename KeyType>
__global__ void regsort_16_2t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_16_2t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_16_4t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_16_4t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_16_8t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_16_8t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_16_16t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_16_16t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 32:

template<typename KeyType>
__global__ void regsort_32_2t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_32_2t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_32_4t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_32_4t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_32_8t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_32_8t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_32_16t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_32_16t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_32_32t_1ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_32_32t_1ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 64:

template<typename KeyType>
__global__ void regsort_64_4t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_64_4t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_64_8t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_64_8t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_64_16t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_64_16t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_64_32t_2ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_64_32t_2ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 128:

template<typename KeyType>
__global__ void regsort_128_8t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_128_8t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_128_16t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_128_16t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_128_32t_4ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_128_32t_4ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 256:

template<typename KeyType>
__global__ void regsort_256_16t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_256_16t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);
template<typename KeyType>
__global__ void regsort_256_32t_8ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_256_32t_8ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

// Sorts for size <= 512:

template<typename KeyType>
__global__ void regsort_512_32t_16ept(
  const unsigned* bins,
  unsigned n_segments,
  const KeyType* keys,
  const unsigned* seg_offsets,
  unsigned* permutations);
template<typename KeyType>
__global__ void
regsort_512_32t_16ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);

#endif
