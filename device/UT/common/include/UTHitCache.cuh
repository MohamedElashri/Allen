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

#include "memory_optim.cuh"
#include "BinarySearch.cuh"

// Basic
#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"

namespace {
  template<unsigned BitMask = 0b1, typename T>
  __device__ inline void set_last_bits(T& val, const uint8_t bits)
  {
    static_assert(sizeof(T) == sizeof(uint32_t));
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
    uint32_t val_as_bits = Allen::device::bit_cast<uint32_t>(val);
    val_as_bits = (val_as_bits & ~BitMask) | (bits & BitMask);
    val = Allen::device::bit_cast<T>(val_as_bits);
#else
    uint32_t val_as_bits = *reinterpret_cast<const uint32_t*>(&val);
    val_as_bits = (val_as_bits & ~BitMask) | (bits & BitMask);
    val = *reinterpret_cast<const T*>(&val_as_bits);
#endif
  }

  template<unsigned BitMask = 0b1, typename T>
  __device__ inline uint8_t get_last_bits(const T val)
  {
    static_assert(sizeof(T) == sizeof(uint32_t));
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
    uint32_t val_as_bits = Allen::device::bit_cast<uint32_t>(val);
    return val_as_bits & BitMask;
#else
    uint32_t val_as_bits = *reinterpret_cast<const uint32_t*>(&val);
    return val_as_bits & BitMask;
#endif
  }
} // namespace

namespace UT {
  // Unlike normal UT hits, we use yMid and HalfDy to simplify operations and remove the lhcb id and plane code
  struct MiniHit {
  private:
    float m_xAtYEq0;
    float m_zAtYEq0;
    float m_yMid;
    float m_HalfDy;
    float m_dxDy;

  public:
    __device__ inline float& xAtYEq0() { return m_xAtYEq0; }
    __device__ inline float& zAtYEq0() { return m_zAtYEq0; }
    __device__ inline float& yMid() { return m_yMid; }
    __device__ inline float& HalfDy() { return m_HalfDy; }
    __device__ inline float& dxDy() { return m_dxDy; }

  public:
    __device__ inline float xAtYEq0() const { return m_xAtYEq0; }
    __device__ inline float zAtYEq0() const { return m_zAtYEq0; }
    __device__ inline float yMid() const { return m_yMid; }
    __device__ inline float HalfDy() const { return m_HalfDy; }
    __device__ inline float dxDy() const { return m_dxDy; }

  public:
    __device__ inline float xAt(const float y) const { return xAtYEq0() + y * dxDy(); }
    __device__ inline bool isYCompatible(const float y, const float tol) const
    {
      return fabsf(y - yMid()) <= (HalfDy() + tol);
    }
    __device__ inline bool isNotYCompatible(const float y, const float tol) const { return !isYCompatible(y, tol); }
    __device__ inline float yMin() const { return yMid() - HalfDy(); }
    __device__ inline float yMax() const { return yMid() + HalfDy(); }
  };

  // Automatically manage the shared memory and global memory usage
  template<unsigned N>
  struct SmartHitsCache {
    // We cache (xAtYEq0), (zAtYEq0), (yMid), (dxDy + dy) as 4 half_t
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
    using ElementType = float4;
#else
    struct __align__(8) ElementType
    {
      half2 x;
      half2 y;
    };
#endif
    constexpr static unsigned NumElements = N;

    // shared data
    ElementType* m_data;

    // global data
    const UT::ConstHits* m_ut_hits;

    // offsets
    unsigned short m_layer_offset;

    // layer constants
    float m_mean_dxDy, m_mean_z, m_mean_half_dy[2];

    // Constructor
    __device__ SmartHitsCache(ElementType* shared_memory) : m_data(shared_memory) {}

    // Constants
    __device__ inline float mean_dxDy() const { return m_mean_dxDy; }
    __device__ inline float mean_z() const { return m_mean_z; }
    __device__ inline auto HitOffset() const { return m_layer_offset; }

    // Cache layer
    __device__ inline auto cache_layer(
      const UT::HitOffsets& ut_hit_offsets,
      const UT::ConstHits& ut_hits,
      const UT::Constants::PerLayerInfo* layer_info,
      const unsigned short layer)
    {
      // Compute offset
      const unsigned layer_offset = ut_hit_offsets.layer_offset(layer);
      const unsigned event_offset = ut_hit_offsets.event_offset();
      m_layer_offset = layer_offset - event_offset;
      const unsigned layer_number_of_hits = ut_hit_offsets.layer_number_of_hits(layer);

      // Use global memory if it doesn't fit in shared memory
      m_ut_hits = (layer_number_of_hits > NumElements) ? &ut_hits : nullptr;
      if (m_ut_hits) return;

      // Fill constants to improve the precision
      m_mean_dxDy = layer_info->mean_dxDy[layer];
      m_mean_z = layer_info->mean_z[layer];
      m_mean_half_dy[0] = layer_info->two_dy[layer][0] / 2;
      m_mean_half_dy[1] = layer_info->two_dy[layer][1] / 2;

      // Fill all hits
      const auto threshold_dy = m_mean_half_dy[0] + m_mean_half_dy[1];
      for (unsigned hit_idx = threadIdx.x; hit_idx < layer_number_of_hits; hit_idx += blockDim.x) {
        const unsigned short global_idx = m_layer_offset + hit_idx;

        const uint8_t dy_idx = fabsf(ut_hits.yBegin(global_idx) - ut_hits.yEnd(global_idx)) > threshold_dy;

        ElementType element_data;

#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
        element_data.x = ut_hits.xAtYEq0(global_idx);
        element_data.y = ut_hits.zAtYEq0(global_idx) - m_mean_z;
        element_data.z = ut_hits.yMid(global_idx);
        element_data.w = ut_hits.dxDy(global_idx) - m_mean_dxDy;
        set_last_bits(element_data.w, dy_idx);
#else
        element_data.x =
          __float22half2_rn(float2 {ut_hits.xAtYEq0(global_idx), ut_hits.zAtYEq0(global_idx) - m_mean_z});
        element_data.y = __float22half2_rn(float2 {ut_hits.yMid(global_idx), ut_hits.dxDy(global_idx) - m_mean_dxDy});
        set_last_bits(element_data.y, dy_idx);
#endif
        m_data[hit_idx] = element_data;
      }
    }

    // Get hit
    __device__ inline MiniHit hit(unsigned short hit_idx)
    {
      MiniHit out;

      if (m_ut_hits) {
        const unsigned short global_idx = m_layer_offset + hit_idx;
        out.xAtYEq0() = m_ut_hits->xAtYEq0(global_idx);
        out.zAtYEq0() = m_ut_hits->zAtYEq0(global_idx);
        out.yMid() = m_ut_hits->yMid(global_idx);
        out.HalfDy() = fabsf(m_ut_hits->yBegin(global_idx) - m_ut_hits->yEnd(global_idx)) / 2;
        out.dxDy() = m_ut_hits->dxDy(global_idx);
      }
      else {
        ElementType element_data = m_data[hit_idx];
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
        out.xAtYEq0() = element_data.x;
        out.zAtYEq0() = element_data.y;
        out.yMid() = element_data.z;
        out.HalfDy() = m_mean_half_dy[get_last_bits(element_data.w)];
        set_last_bits(element_data.w, 0);
        out.dxDy() = element_data.w;
#else
        float2 first = __half22float2(element_data.x);
        float2 second = __half22float2(element_data.y);
        out.xAtYEq0() = first.x;
        out.zAtYEq0() = first.y + m_mean_z;
        out.yMid() = second.x;
        out.HalfDy() = m_mean_half_dy[get_last_bits(element_data.y)];
        set_last_bits(element_data.y, 0);
        out.dxDy() = second.y + m_mean_dxDy;
#endif
      }
      return out;
    }
  };

  struct SectorHelper {
    const float* m_sector_xs = nullptr;
    const unsigned* m_sector_hit_offsets = nullptr;
    unsigned m_size = 0;
    unsigned m_offset = 0;

    __device__ inline auto cache_layer(
      const UT::HitOffsets& ut_hit_offsets,
      const float* sector_xs,
      const unsigned* sector_layer_offsets,
      const unsigned layer)
    {
      // Load sizes
      const unsigned short layer_offset = sector_layer_offsets[layer];
      m_size = sector_layer_offsets[layer + 1] - layer_offset;

      // Load xs
      m_sector_xs = sector_xs + layer_offset;

      // Load hit offsets
      m_offset = ut_hit_offsets.sector_group_offset(layer_offset);
      m_sector_hit_offsets = ut_hit_offsets.m_ut_hit_offsets + layer_offset;
    }

    __device__ inline auto get_hit_range(const float xmin, const float xmax) const
    {
      //
      // note: considering there are 4 different z position per each layer, we also add neighbor sectors.
      //      this is to avoid the case that the track is going to the neighbor sector.
      //
      auto sector_min = binary_search_rightmost<float>(m_sector_xs, m_size, xmin) - 1;
      if (sector_min < 0) sector_min = 0;

      auto sector_max = linear_search<float>(m_sector_xs, m_size, xmax, sector_min) + 1;
      if (sector_max > static_cast<int>(m_size)) sector_max = m_size;

      return uint2 {m_sector_hit_offsets[sector_min] - m_sector_hit_offsets[0],
                    m_sector_hit_offsets[sector_max] - m_sector_hit_offsets[0]};
    }
  };
} // namespace UT

//   struct SectorHelper {
//     const float* m_sector_xs = nullptr;
//     const unsigned* m_sector_hit_offsets = nullptr;
//     unsigned m_size = 0;
//     unsigned m_offset = 0;

//     __device__ inline auto cache_layer(
//       const UT::HitOffsets& ut_hit_offsets,
//       const float* sector_xs,
//       const unsigned* sector_layer_offsets,
//       const unsigned layer)
//     {
//       // Load sizes
//       const unsigned short layer_offset = sector_layer_offsets[layer];
//       m_size = sector_layer_offsets[layer + 1] - layer_offset;

//       // Load xs
//       m_sector_xs = sector_xs + layer_offset;

//       // Load hit offsets
//       m_offset = ut_hit_offsets.sector_group_offset(layer_offset);
//       m_sector_hit_offsets = ut_hit_offsets.m_ut_hit_offsets + layer_offset;
//     }

//     __device__ inline auto get_hit_range(const float xmin, const float xmax) const
//     {
//       //
//       // note: considering there are 4 different z position per each layer, we also add neighbor sectors.
//       //      this is to avoid the case that the track is going to the neighbor sector.
//       //
//       auto sector_min = binary_search_rightmost<float>(m_sector_xs, m_size, xmin) - 1;
//       if (sector_min < 0) sector_min = 0;

//       auto sector_max = linear_search<float>(m_sector_xs, m_size, xmax, sector_min) + 1;
//       if (sector_max > static_cast<int>(m_size)) sector_max = m_size;

//       return uint2 {m_sector_hit_offsets[sector_min] - m_sector_hit_offsets[0],
//                     m_sector_hit_offsets[sector_max] - m_sector_hit_offsets[0]};
//     }
//   };
// `
// }