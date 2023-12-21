/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
\*****************************************************************************/
#pragma once

#include "memory_optim.cuh"
#include "DownstreamConstants.cuh"
#include "DownstreamHelper.cuh"
#include "DownstreamStructs.cuh"
#include "BinarySearch.cuh"

// Basic
#include "UTEventModel.cuh"

/**
 * @brief Downstream cache
 * @details This file contains the cache helper for downstream tracking.
 *          The cache is used to reduce the global memory access.
 *          Two caches are implemented:
 *            - Hit cache: cache the hits in the current layer
 *            - Sector cache: cache the sector information in the current layer
 */

namespace Downstream {

  namespace DownstreamCache {

    namespace detail {
      static constexpr float y_width_factor = 255 / 50.f; // Y width can not be larger than 50. mm

      __device__ inline float decode_y_width(uint8_t data) { return std::round(data / y_width_factor); }

      __device__ inline uint8_t encode_y_width(float data) { return data * y_width_factor; }
    }; // namespace detail

    struct HitCache {
      constexpr static unsigned NumRow = DownstreamParameters::MaxNumHitCachedSharedMemory;
      constexpr static unsigned RowSize = sizeof(half_t) * 3 + sizeof(uint8_t);
      constexpr static unsigned TotalMemorySize = RowSize * NumRow;

      // basics
      half_t* m_data_x;
      half_t* m_data_y;
      half_t* m_data_z;
      uint8_t* m_data_ywidth;
      unsigned short m_size;
      unsigned short m_layer;
      unsigned short m_global_offset;
      float m_z0;

      // memory
      char* m_shared_memory;
      char* m_global_memory;
      unsigned* m_global_count;

      __device__ HitCache(char* shared_memory, char* global_memory, unsigned* global_count) :
        m_shared_memory(shared_memory), m_global_memory(global_memory), m_global_count(global_count)
      {}

      __device__ inline unsigned short size() const { return m_size; }

      __device__ inline float xAtYEq0(const unsigned short hit_idx) const
      {
        assert(hit_idx < m_size);
        return __half2float(m_data_x[hit_idx]);
      }

      __device__ inline float yMid(const unsigned short hit_idx) const
      {
        assert(hit_idx < m_size);
        return __half2float(m_data_y[hit_idx]);
      }

      __device__ inline float yWidth(const unsigned short hit_idx) const
      {
        assert(hit_idx < m_size);

        return detail::decode_y_width(m_data_ywidth[hit_idx]);
      }

      __device__ inline float yMin(const unsigned short hit_idx) const
      {
        assert(hit_idx < m_size);
        return yMid(hit_idx) - yWidth(hit_idx);
      }

      __device__ inline float yMax(const unsigned short hit_idx) const
      {
        assert(hit_idx < m_size);
        return yMid(hit_idx) + yWidth(hit_idx);
      }

      __device__ inline bool isYCompatible(const unsigned hit_idx, const float y, const float tol) const
      {
        return yMin(hit_idx) - tol <= y && y <= yMax(hit_idx) + tol;
      }

      __device__ inline bool isNotYCompatible(const unsigned hit_idx, const float y, const float tol) const
      {
        return yMin(hit_idx) - tol > y || y > yMax(hit_idx) + tol;
      }

      __device__ inline float zAtYEq0(const unsigned short hit_idx) const
      {
        assert(hit_idx < m_size);
        return __half2float(m_data_z[hit_idx]) + m_z0;
      }

      __device__ inline auto HitOffset() const { return m_global_offset; }

      __device__ inline auto cache_layer(
        const UT::HitOffsets& ut_hit_offsets,
        const UT::ConstHits& ut_hits,
        const float mean_layer_z,
        const unsigned short layer,
        const unsigned short tid,
        const unsigned short bdim)
      {
        // Load layer
        m_layer = layer;

        // Load z0
        m_z0 = mean_layer_z;

        // Load size
        m_size = ut_hit_offsets.layer_number_of_hits(layer);
        const unsigned layer_offset = ut_hit_offsets.layer_offset(layer);
        const unsigned event_offset = ut_hit_offsets.event_offset();
        m_global_offset = layer_offset - event_offset;

        // Preapare the cache ( if it doesn't fit in shared memory, cache it into global memory instead. )
        // Note: if it should fit to global memory, the memory alignment is required; otherwise, the reinterpret_cast
        // will crash.

        const unsigned aligned_num_row = (m_size % 2 == 0) ? m_size : (unsigned(m_size / 2) + 1u) * 2u;
        shared_or_global(
          aligned_num_row * RowSize, // required size
          NumRow * RowSize,          // max shared memory size
          m_shared_memory,           // shared memory
          m_global_memory,           // global memory
          m_global_count,            // global memory counter
          [&](char* memory) {
            this->m_data_x = reinterpret_cast<half_t*>(memory);
            this->m_data_y = reinterpret_cast<half_t*>(memory + (sizeof(half_t)) * aligned_num_row);
            this->m_data_z = reinterpret_cast<half_t*>(memory + (sizeof(half_t) * 2) * aligned_num_row);
            this->m_data_ywidth = reinterpret_cast<uint8_t*>(memory + (sizeof(half_t) * 3) * aligned_num_row);
          });

        // Load hits
        for (unsigned hit_idx = tid; hit_idx < m_size; hit_idx += bdim) {
          // idx in global memory
          const unsigned short global_idx = m_global_offset + hit_idx;

          // X and Z
          m_data_x[hit_idx] = __float2half(ut_hits.xAtYEq0(global_idx));
          m_data_z[hit_idx] = __float2half(ut_hits.zAtYEq0(global_idx) - m_z0);

          // Y
          const float yBegin = ut_hits.yBegin(global_idx);
          const float yEnd = ut_hits.yEnd(global_idx);
          m_data_y[hit_idx] = __float2half((yBegin + yEnd) / 2);
          m_data_ywidth[hit_idx] = detail::encode_y_width(fabsf(yBegin - yEnd) / 2);
        }
      }
    };

    //
    // Sector cache
    // Note: we do a lot of binary search to find the right sector, so caching this to shared memory is very important.
    //
    struct SectorCache {

      constexpr static unsigned NumRow = DownstreamParameters::MaxNumCachedSector;
      constexpr static unsigned RowSize = sizeof(float) + sizeof(ushort);
      constexpr static unsigned TotalMemorySize = RowSize * NumRow;

      float* m_sector_xs;
      ushort* m_sector_hit_offsets;
      ushort m_size;

      __device__ SectorCache(char* shared_memory) :
        m_sector_xs(reinterpret_cast<float*>(shared_memory)),
        m_sector_hit_offsets(reinterpret_cast<ushort*>(shared_memory + NumRow * sizeof(float)))
      {}

      __device__ inline auto cache_layer(
        const UT::HitOffsets& ut_hit_offsets,
        const float* sector_xs,
        const unsigned* sector_layer_offsets,
        const unsigned layer,
        const unsigned tid,
        const unsigned bdim)
      {
        // Load sizes
        const unsigned short layer_offset = sector_layer_offsets[layer];
        m_size = sector_layer_offsets[layer + 1] - layer_offset;

        // Load xs
        for (unsigned short idx = tid; idx < m_size; idx += bdim) {
          m_sector_xs[idx] = sector_xs[layer_offset + idx];
        };

        // Load hit offsets
        for (unsigned short idx = tid; idx <= m_size; idx += bdim) {
          m_sector_hit_offsets[idx] =
            ut_hit_offsets.sector_group_offset(layer_offset + idx) - ut_hit_offsets.sector_group_offset(layer_offset);
        };
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
        if (sector_max > m_size) sector_max = m_size;

        return ushort2 {m_sector_hit_offsets[sector_min], m_sector_hit_offsets[sector_max]};
      }
    };
  } // namespace DownstreamCache
} // namespace Downstream