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

namespace Downstream::Structs {
  using LayerHitRanges = std::array<short2, 4>;

  struct alignas(4) HitCombinations {
    uint16_t layers[4];
  } __attribute__((packed));

  // struct SciFiCandidate
  // {
  //   uint16_t event_number;
  //   uint16_t scifi_idx;
  //   int8_t sectors[4][4] = {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}};
  // };

  struct SciFiCandidate {
    uint16_t event_number;
    uint16_t scifi_idx;
    LayerHitRanges hit_ranges[4];
  };

  struct DownstreamSeed {
    uint16_t event_number;
    uint16_t scifi_index;
    LayerHitRanges hits;
  };

  struct alignas(4) CompactTrack {
    unsigned scifi_idx;
    int16_t ut_hits[4];
  } __attribute__((packed));

  struct alignas(16) CompactState {
    static constexpr float m_z = 2484.6f;
    float m_x, m_y, m_tx, m_ty;

    __host__ __device__ float z() const { return m_z; }

    __host__ __device__ float x() const { return m_x; }
    __host__ __device__ float y() const { return m_y; }
    __host__ __device__ float tx() const { return m_tx; }
    __host__ __device__ float ty() const { return m_ty; }

    __host__ __device__ float& x() { return m_x; }
    __host__ __device__ float& y() { return m_y; }
    __host__ __device__ float& tx() { return m_tx; }
    __host__ __device__ float& ty() { return m_ty; }

    __host__ __device__ float xAt(float z) const { return m_x + m_tx * (z - m_z); }
    __host__ __device__ float yAt(float z) const { return m_y + m_ty * (z - m_z); }
  };
} // namespace Downstream::Structs