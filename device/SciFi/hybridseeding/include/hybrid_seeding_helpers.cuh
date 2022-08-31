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
    __device__ constexpr int nLayers = 6;
    __device__ constexpr float z[nLayers] = {7826.106f, 8035.9048f, 8508.1064f, 8717.9043f, 9193.1064f, 9402.9043f};
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
    int idx[SciFi::Constants::n_xzlayers] = {0};
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
    constexpr unsigned int nLayers = 6;
    constexpr float angle = 0.086;   // FIXME
    constexpr float yCenter = 2.f;   // FIXME
    constexpr float yEdge = -2700.f; // FIXME
    __device__ constexpr float z[nLayers] =
      {8577.8691f, 7895.9189f, 9333.041, 8648.1543f, 9262.9824f, 7966.1035f}; // FIXME
    __device__ constexpr float uv[nLayers] = {1., 1., -1., -1., 1., -1.};     // 1 for u, -1 for v //FIXME
    __device__ constexpr float dz[nLayers] = {z[0] - hybrid_seeding::z_ref,
                                              z[1] - hybrid_seeding::z_ref,
                                              z[2] - hybrid_seeding::z_ref,
                                              z[3] - hybrid_seeding::z_ref,
                                              z[4] - hybrid_seeding::z_ref,
                                              z[5] - hybrid_seeding::z_ref};
    __device__ constexpr float dz2[nLayers] = {dz[0] * dz[0] * (1.f + hybrid_seeding::dRatio * dz[0]),
                                               dz[1] * dz[1] * (1.f + hybrid_seeding::dRatio * dz[1]),
                                               dz[2] * dz[2] * (1.f + hybrid_seeding::dRatio * dz[2]),
                                               dz[3] * dz[3] * (1.f + hybrid_seeding::dRatio * dz[3]),
                                               dz[4] * dz[4] * (1.f + hybrid_seeding::dRatio * dz[4]),
                                               dz[5] * dz[5] * (1.f + hybrid_seeding::dRatio * dz[5])};
    __device__ constexpr float dxDy[nLayers] =
      {angle * uv[0], angle* uv[1], angle* uv[2], angle* uv[3], angle* uv[4], angle* uv[5]};
  } // namespace geomInfo

  struct multiHitCombination {
    int number_of_hits {1};
    int idx[SciFi::Constants::n_uvlayers] = {SciFi::Constants::INVALID_IDX};
    float y[SciFi::Constants::n_uvlayers] = {0};
    float ay;
    float by;
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
    static constexpr unsigned maxTriplets = 3000;
    __device__ Triplet(unsigned indices) : indices(indices) {}
    __device__ Triplet(int idx0, int idx1, int idx2) : indices((idx2 << 20) | (idx1 << 10) | idx0) {}
    __device__ int idx0() { return indices & 1023; }
    __device__ int idx1() { return (indices >> 10) & 1023; }
    __device__ int idx2() { return (indices >> 20) & 1023; }
    unsigned indices;
  };
} // namespace seeding
