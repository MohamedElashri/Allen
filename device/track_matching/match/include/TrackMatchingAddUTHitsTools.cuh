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
    VeloToUTExtrapolator() = default;

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

    __device__ inline auto txAtZ(const float z) const
    {
      return m_vp_tx + 2 * m_gamma * (z - Velo::Constants::z_endVelo);
    }

    // Useful updater
    __device__ inline auto get_new_gamma(const float z, const float x)
    {
      return (x - (m_vp_x + m_vp_tx * (z - Velo::Constants::z_endVelo))) /
             ((z - Velo::Constants::z_endVelo) * (z - Velo::Constants::z_endVelo));
    }

    // Tolerances
    __device__ inline auto get_tolerance(const float* parameters)
    {
      float3 tol;
      tol.x = parameters[0] + parameters[1] * m_inv_p;
      tol.y = parameters[2];
      tol.z = parameters[3];
      return (tol.x > tol.z) ? tol.z : (tol.x < tol.y) ? tol.y : tol.x;
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
