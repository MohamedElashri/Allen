/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
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

namespace track_matching::tools {
  struct VeloToUTExtrapolator {
  private:
    float m_vp_x;
    float m_vp_y;
    float m_vp_tx;
    float m_vp_ty;
    float m_inv_p;
    float m_gamma;
    bool m_is_first_hit;

  public:
    __device__ VeloToUTExtrapolator() = default;

    __device__ VeloToUTExtrapolator(
      const float vp_x,
      const float vp_y,
      const float vp_tx,
      const float vp_ty,
      const float qop_polarity) :
      m_vp_x(vp_x),
      m_vp_y(vp_y), m_vp_tx(vp_tx), m_vp_ty(vp_ty), m_inv_p(fabsf(qop_polarity)), m_is_first_hit(true)
    {
      // Use qop*polarity to estimate first gamma
      m_gamma = (7.707063E-11f) + (-7.817364E-03f) * qop_polarity;
    }

    __device__ VeloToUTExtrapolator(
      const float vp_x,
      const float vp_y,
      const float vp_tx,
      const float vp_ty,
      const float qop,
      const float gamma) :
      m_vp_x(vp_x),
      m_vp_y(vp_y), m_vp_tx(vp_tx), m_vp_ty(vp_ty), m_inv_p(fabsf(qop)), m_gamma(gamma), m_is_first_hit(false)
    {}

    __device__ inline auto is_first_hit() const { return m_is_first_hit; };

    // Useful extrapolation function
    __device__ inline auto xAtZ(const float z) const
    {
      return m_vp_x + m_vp_tx * (z - Velo::Constants::z_endVelo) +
             m_gamma * (z - Velo::Constants::z_endVelo) * (z - Velo::Constants::z_endVelo);
    }
    __device__ inline auto yAtZ(const float z) const { return m_vp_y + m_vp_ty * (z - Velo::Constants::z_endVelo); }

    // Useful updater
    __device__ inline auto get_new_gamma(const float z, const float x)
    {
      return (x - (m_vp_x + m_vp_tx * (z - Velo::Constants::z_endVelo))) /
             ((z - Velo::Constants::z_endVelo) * (z - Velo::Constants::z_endVelo));
    }

    // Tolerances

    __device__ inline auto xTol_Loose(const unsigned layer, const std::array<float, 3>& scaling_factor)
    {
      assert(layer < 4);
      float3 tol;
      switch (layer) {
      case 0:
        tol = {(-2.403749E+07f) * m_inv_p * m_inv_p + (2.790774E+04f) * m_inv_p + (9.677745E-01f), 1.7f, 8.f};
        break;
      case 1:
        tol = {(-2.444682E+07f) * m_inv_p * m_inv_p + (2.878164E+04f) * m_inv_p + (1.019200E+00f), 1.8f, 8.f};
        break;
      case 2:
        tol = {(-2.591807E+07f) * m_inv_p * m_inv_p + (3.157388E+04f) * m_inv_p + (1.222866E+00f), 2.1f, 9.f};
        break;
      default:
        tol = {(-2.579871E+07f) * m_inv_p * m_inv_p + (3.214443E+04f) * m_inv_p + (1.255346E+00f), 2.1f, 9.f};
        break;
      }
      tol.x *= scaling_factor[0];
      tol.y *= scaling_factor[1];
      tol.z *= scaling_factor[2];
      return (tol.x > tol.z) ? tol.z : (tol.x < tol.y) ? tol.y : tol.x;
    }

    __device__ inline auto xTol_Tight(const unsigned layer, const std::array<float, 3>& scaling_factor)
    {
      assert(layer >= 1 && layer < 4);
      float3 tol;
      switch (layer) {
      case 1:
        tol = {(-6.017959E+05f) * m_inv_p * m_inv_p + (2.520898E+03f) * m_inv_p + (1.628293E-01f), 0.4f, 2.f};
        break;
      case 2:
        tol = {(-3.408152E+06f) * m_inv_p * m_inv_p + (7.559409E+03f) * m_inv_p + (2.971365E-01f), 0.6f, 3.f};
        break;
      default:
        tol = {(-3.991361E+06f) * m_inv_p * m_inv_p + (8.843961E+03f) * m_inv_p + (3.236134E-01f), 0.7f, 3.f};
        break;
      }
      tol.x *= scaling_factor[0];
      tol.y *= scaling_factor[1];
      tol.z *= scaling_factor[2];
      return (tol.x > tol.z) ? tol.z : (tol.x < tol.y) ? tol.y : tol.x;
    }

    __device__ inline auto xTol(
      const unsigned layer,
      const std::array<float, 3>& loose_scaling_factor,
      const std::array<float, 3>& tight_scaling_factor)
    {
      return m_is_first_hit ? xTol_Loose(layer, loose_scaling_factor) : xTol_Tight(layer, tight_scaling_factor);
    }

    __device__ inline auto yTol(const unsigned layer, const std::array<float, 3>& scaling_factor)
    {
      float3 tol;
      switch (layer) {
      case 0:
        tol = {(1.688064E+07f) * m_inv_p * m_inv_p + (-3.828492E+02f) * m_inv_p + (-4.629343E-02f), 1.f, 2.f};
        break;
      case 1:
        tol = {(1.918749E+07f) * m_inv_p * m_inv_p + (-4.954684E+02f) * m_inv_p + (-3.321084E-02f), 1.f, 2.f};
        break;
      case 2:
        tol = {(1.834241E+07f) * m_inv_p * m_inv_p + (1.445161E+03f) * m_inv_p + (-1.085821E-01f), 1.f, 3.f};
        break;
      default:
        tol = {(1.595784E+07f) * m_inv_p * m_inv_p + (2.247124E+03f) * m_inv_p + (-1.463718E-01f), 1.f, 3.f};
        break;
      }
      tol.x *= scaling_factor[0];
      tol.y *= scaling_factor[1];
      tol.z *= scaling_factor[2];
      return (tol.x > tol.z) ? tol.z : (tol.x < tol.y) ? tol.y : tol.x;
    }
  };

  struct UTHitCache {
    constexpr static unsigned NumRow = 1024;
    constexpr static unsigned RowSize = sizeof(half_t) * 4;
    constexpr static unsigned TotalMemorySize = RowSize * NumRow;

    // basics
    half_t* m_data_x;
    half_t* m_data_z;
    half_t* m_data_ymin;
    half_t* m_data_ymax;
    unsigned short m_size;
    unsigned short m_layer;
    unsigned short m_global_offset;
    float m_z0;

    // memory
    char* m_shared_memory;
    char* m_global_memory;
    unsigned* m_global_count;

    __device__ UTHitCache(char* shared_memory, char* global_memory, unsigned* global_count) :
      m_shared_memory(shared_memory), m_global_memory(global_memory), m_global_count(global_count)
    {}

    __device__ inline unsigned short size() const { return m_size; }

    __device__ inline float xAtYEq0(const unsigned short hit_idx) const
    {
      assert(hit_idx < m_size);
      return __half2float(m_data_x[hit_idx]);
    }

    __device__ inline float yMin(const unsigned short hit_idx) const
    {
      assert(hit_idx < m_size);
      return __half2float(m_data_ymin[hit_idx]);
    }

    __device__ inline float yMax(const unsigned short hit_idx) const
    {
      assert(hit_idx < m_size);
      return __half2float(m_data_ymax[hit_idx]);
    }

    __device__ inline float yMid(const unsigned short hit_idx) const
    {
      assert(hit_idx < m_size);
      return (yMin(hit_idx) + yMax(hit_idx)) / 2;
    }

    __device__ inline float yWidth(const unsigned short hit_idx) const
    {
      assert(hit_idx < m_size);
      return (yMax(hit_idx) - yMin(hit_idx)) / 2;
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
      const unsigned short layer)
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

      const unsigned aligned_num_row = m_size + (m_size % 2);
      shared_or_global(
        aligned_num_row * RowSize, // required size
        NumRow * RowSize,          // max shared memory size
        m_shared_memory,           // shared memory
        m_global_memory,           // global memory
        m_global_count,            // global memory counter
        [&](char* memory) {
          this->m_data_x = reinterpret_cast<half_t*>(memory);
          this->m_data_z = reinterpret_cast<half_t*>(memory + (sizeof(half_t)) * aligned_num_row);
          this->m_data_ymin = reinterpret_cast<half_t*>(memory + (sizeof(half_t) * 2) * aligned_num_row);
          this->m_data_ymax = reinterpret_cast<half_t*>(memory + (sizeof(half_t) * 3) * aligned_num_row);
        });

      // Load hits
      for (unsigned hit_idx = threadIdx.x; hit_idx < m_size; hit_idx += blockDim.x) {
        // idx in global memory
        const unsigned short global_idx = m_global_offset + hit_idx;

        // X and Z
        m_data_x[hit_idx] = __float2half(ut_hits.xAtYEq0(global_idx));
        m_data_z[hit_idx] = __float2half(ut_hits.zAtYEq0(global_idx) - m_z0);

        // Y
        m_data_ymin[hit_idx] = __float2half(ut_hits.yMin(global_idx));
        m_data_ymax[hit_idx] = __float2half(ut_hits.yMax(global_idx));
      }
    }
  };

  struct UTSectorHelper {
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

  template<typename T, unsigned MaxSize, bool AbsoluteScore = false>
  struct MultiCandidateManager {
    // Intern struct
    T m_container[MaxSize];
    float m_scores[MaxSize];
    int m_worst;
    unsigned m_size;

    // Constructor
    __device__ MultiCandidateManager() : m_worst(-1), m_size(0) {}

    // Functions
    __device__ inline unsigned size() const { return m_size; }

    __device__ inline bool exist() const { return m_size != 0; }

    __device__ inline T& get(const unsigned idx)
    {
      assert(idx < m_size);
      return m_container[idx];
    }

    __device__ inline float& score(const unsigned idx)
    {
      assert(idx < m_size);
      return m_scores[idx];
    }

    __device__ inline T& worst()
    {
      assert(m_worst != -1 & m_worst < m_size);
      return get(m_worst);
    }
    __device__ inline float& worst_score()
    {
      assert(m_worst != -1 & m_worst < m_size);
      return score(m_worst);
    }

    __device__ inline bool can_be_added(const float score)
    {
      if (m_size < MaxSize) return true;
      if constexpr (AbsoluteScore) {
        if (fabsf(score) < fabsf(worst_score())) return true;
      }
      else {
        if (score < worst_score()) return true;
      }
      return false;
    }

    __device__ inline auto update_worst()
    {
      assert(m_size > 0);
      m_worst = 0;
      for (unsigned idx = 1; idx < static_cast<unsigned>(m_size); idx++) {
        if constexpr (AbsoluteScore) {
          if (fabsf(m_scores[idx]) > fabsf(m_scores[m_worst])) m_worst = idx;
        }
        else {
          if (m_scores[idx] > m_scores[m_worst]) m_worst = idx;
        }
      }
    }

    __device__ inline auto add(const T& candidate, const float score)
    {
      if (static_cast<unsigned>(m_size) < MaxSize) {
        m_container[m_size] = candidate;
        m_scores[m_size] = score;
        m_size++;
      }
      else {
        if constexpr (AbsoluteScore) {
          if (fabsf(score) > fabsf(m_scores[m_worst])) return;
        }
        else {
          if (score > m_scores[m_worst]) return;
        }
        m_container[m_worst] = candidate;
        m_scores[m_worst] = score;
      }

      if (m_size == MaxSize) update_worst();
    }
  };

  template<typename T, bool AbsoluteScore = false>
  struct BestCandidateManager {
    __device__ BestCandidateManager() { m_score = Allen::numeric_limits<float>::infinity(); }

    __device__ inline auto best() { return m_candidate; }

    __device__ inline auto score() { return m_score; }

    __device__ inline bool exist() { return Allen::numeric_limits<float>::infinity() != m_score; }

    __device__ inline auto add(const T& candidate, const float& score)
    {
      if constexpr (AbsoluteScore) {
        if (fabsf(score) < fabsf(m_score)) {
          m_candidate = candidate;
          m_score = score;
        };
      }
      else {
        if (score < m_score) {
          m_candidate = candidate;
          m_score = score;
        };
      }
    }

  private:
    T m_candidate;
    float m_score;
  };

} // namespace track_matching::tools