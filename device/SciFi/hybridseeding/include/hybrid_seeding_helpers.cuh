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

#include <tuple>
#include "States.cuh"
#include "SciFiEventModel.cuh"

namespace hybrid_seeding {
  constexpr float z_ref = 8520.f;
  constexpr float dRatio = -0.00028f;
  constexpr int nLayers = 12;

  template<typename T>
  __device__ unsigned int binary_search_leftmost_unrolled(const T* array, const unsigned array_size, const T& needle)
  {
    unsigned int low = 0;
    unsigned int size = array_size;

    // Unroll 9 time to cover arrays of size max 512
#if defined(__clang__) or defined(__NVCC__)
#pragma unroll
#elif defined(__GNUC__)
#pragma GCC unroll 9
#endif
    for (unsigned int step = 0; step < 9; step++) {
      unsigned int half = size / 2;
      low += (array[low + half] < needle) * (size - half);
      size = half;
    } // while (size > 0);

    return low;
  }

} // namespace hybrid_seeding

namespace seed_xz {
  namespace geomInfo {
    constexpr int nLayers = 6;
    constexpr float z[nLayers] = {7826.106f, 8035.9048f, 8508.1064f, 8717.9043f, 9193.1064f, 9402.9043f};
    constexpr unsigned x_layers_number[6] {0, 3, 4, 7, 8, 11};
  }; // namespace geomInfo
  // Structure
  struct TwoHitCombination {
    float tx;
    float xProj;
    float xRef;
    float invP;
    float minPara;
    float maxPara;
  };

  struct multiHitCombination {
    unsigned idx[SciFi::Constants::n_xzlayers] = {0};
    float ax;
    float bx;
    float cx;
    float delta_x[6] = {0.f};
  };

  inline int intIndex(int part, int event_number) { return part + SciFi::Constants::n_parts * event_number; };
  inline int trackIndex(int event_number) { return event_number * SciFi::Constants::Nmax_seed_xz; };
} // namespace seed_xz

namespace seed_uv {
  namespace geomInfo {
    constexpr int nLayers = 6;
    constexpr float yCenter = 2.f;   // FIXME
    constexpr float yEdge = -2700.f; // FIXME
    // matching the hardcoded vector used before {8577.8691f,7895.9189f, 9333.041, 8648.1543f, 9262.9824f, 7966.1035f}
    constexpr unsigned uv_layers_number[nLayers] {5, 1, 10, 6, 9, 2};
  } // namespace geomInfo

  struct multiHitCombination {
    int number_of_hits {1};
    unsigned idx[SciFi::Constants::n_uvlayers] = {SciFi::Constants::INVALID_IDX};
    float y[SciFi::Constants::n_uvlayers] = {0};
    float ay = {0};
    float by = {0};
    float chi2;
    float p;
    float qop;
    float x, z;
  };
  inline int trackIndex(int event_number) { return event_number * SciFi::Constants::Nmax_seeds; }; // FIXME
} // namespace seed_uv

namespace seeding {
  inline __device__ int searchBin(const float needle, const float* hits, int nhits)
  {
    int low = 0;
    int size = nhits;

    do {
      int half = size / 2;
      low += (hits[low + half] <= needle) * (size - half);
      size = half;
    } while (size > 0);

    return low - (low > 0 && std::fabs(hits[low] - needle) >= std::fabs(hits[low - 1] - needle));
  }
  inline __device__ int searchBin(const float needle, const float* hits, int startpos, int nhits)
  {
    int low = startpos;
    int size = nhits;

    do {
      int half = size / 2;
      low += (hits[low + half] <= needle) * (size - half);
      size = half;
    } while (size > 0);

    return low - (low > 0 && std::fabs(hits[low] - needle) >= std::fabs(hits[low - 1] - needle));
  }

  struct HitCache {
    inline __device__ float& hit(unsigned layer, unsigned hit) { return data[start[layer] + hit]; }
    inline __device__ float* layer(unsigned layer) { return &data[start[layer]]; }
    float* data;       // in shared or global
    unsigned start[6]; // in registers
    unsigned size[6];  // in registers
  };

  struct Triplet {
    static constexpr unsigned maxTriplets = 10000;
    __device__ Triplet(unsigned indices) : indices(indices) {}
    __device__ Triplet(int idx0, int idx1, int idx2) : indices((idx2 << 20) | (idx1 << 10) | idx0) {}
    __device__ int idx0() { return indices & 1023; }
    __device__ int idx1() { return (indices >> 10) & 1023; }
    __device__ int idx2() { return (indices >> 20) & 1023; }
    unsigned indices;
  };

  struct HoughSearch {
    // uses 12 = 2 * 6 32bits registers
    uint64_t layers[6];

    // reset all sets and counts to 0
    __device__ void reset()
    {
      for (int i = 0; i < 6; i++) {
        layers[i] = 0;
      }
    }

    // Set a bin in a given layer
    __device__ void setBin(int layer, int bin) { layers[layer] |= 1ll << bin; }

    // clear a bin in all layers and set the bin count to 0
    __device__ void clearBin(int bin)
    {
      for (int i = 0; i < 3; i++) { // only clear the count part
        layers[i] &= ~(1ll << bin);
      }
    }

    // Count unique layers in all bins in place, count result in first 3 layers
    __device__ void popcount()
    {
      // L0 + L1 (max=2, 2bits)
      uint64_t c = layers[0] & layers[1];
      layers[0] ^= layers[1];
      layers[1] = c;

      // L0+L1+L2 (max=3, 2bits)
      c = layers[0] & layers[2];
      layers[0] ^= layers[2];
      layers[1] ^= c;
      layers[2] = 0;

      // rest (3bits)
      for (int layer = 3; layer < 6; layer++) {
        c = layers[layer];
        for (int i = 0; i < 3; i++) { // add and propagate carry
          uint64_t a = layers[i];
          layers[i] = a ^ c;
          c = c & a;
        }
      }
    }

    // Return the count for a given bin (debug purpose only)
    __device__ int count(int bin)
    {
      int count = 0;
      for (int i = 0; i < 3; i++) {
        count += ((layers[i] >> bin) & 1) << i;
      }
      return count;
    }

    // Get the bin with maximum count
    __device__ int getBestPos()
    {
      uint64_t mask = (uint64_t) -1;
      for (int i = 2; i >= 0; i--) {
        if ((layers[i] & mask) == 0) continue; // all 0, no new information, skip
        mask &= layers[i];
        if (!(mask & (mask - 1))) { // there is only one bit set
          return __ffsll(mask) - 1;
        }
      }
      if (mask == (uint64_t) -1) return -1; // no results
      return __ffsll(mask) - 1;             // multiple equal result, return smallest index
    }
  };
} // namespace seeding
