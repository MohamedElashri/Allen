/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BinarySearch.cuh"
#include "BackendCommon.h"
#include "DownstreamConstants.cuh"

/**
 * @brief This file contains the helper classes for the downstream tracking algorithm
 * @details This contains helper to unroll loops, multi candidate manager and best candidate manager
 * @file DownstreamHelpers.cuh
 */

namespace Downstream {
  namespace DownstreamHelpers {

    // Helper to force the compiler to unroll a loop
    template<int Start, int End, int Step = 1, typename F, typename... Args>
    constexpr inline __attribute__((always_inline)) void unwind(F const& f, Args&&... args)
    {
      static_assert(Step != 0);
      static_assert((Step > 0 && Start <= End) || (Step < 0 && Start >= End));
      if constexpr (Start != End) {
        f(std::integral_constant<int, Start> {}, args...);
        unwind<Start + Step, End, Step>(f, args...);
      }
    }
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
  } // namespace DownstreamHelpers
} // namespace Downstream
