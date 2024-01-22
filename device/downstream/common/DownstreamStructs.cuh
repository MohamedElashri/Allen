/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
\*****************************************************************************/
#pragma once

#include "DownstreamConstants.cuh"
#include "UTEventModel.cuh"

/**
 * @brief This is definition file for downstream specific structs and enums.
 * @details Downstream structs contain the output table for FindHits algorithm.
 * The output table for FindHits algorithm is also used for cache some useful variables in SOA.
 *
 */

namespace Downstream {
  namespace DownstreamEnums {
    enum LayerInfo : uint8_t {
      X0 = 0b0000'0001,
      U1 = 0b0000'0010,
      V2 = 0b0000'0100,
      X3 = 0b0000'1000,
      UV = 0b0000'0110
    };

    __device__ constexpr uint8_t layer_masks[4] = {X0, U1, V2, X3};
  } // namespace DownstreamEnums

  namespace DownstreamStructs {
    //
    // Output table for FindHits algorithm
    //
    // Note: this is not only the output, but also used for cache some useful variables in SOA.
    template<typename T>
    struct FindHits_OutputTable_t {
      constexpr static unsigned MaxNumUVHits = DownstreamParameters::MaxNumSelectedUVhitPerRow;

      constexpr static unsigned NumRow = Downstream::DownstreamParameters::MaxNumSelectedX3Hit;
      constexpr static unsigned RowSize =
        sizeof(unsigned) * (2 + 2 * MaxNumUVHits) + sizeof(float) * (8 + 2 * MaxNumUVHits);
      constexpr static unsigned TotalMemorySize = NumRow * RowSize;

      Allen::forward_type_t<T, unsigned>* m_hits;       // (x0, x3, u1[MaxNumUVHits], v2[MaxNumUVHits])
      Allen::forward_type_t<T, float>* m_extrapolation; // (tx, ty, xMag, yMag, zMag, qop)
      Allen::forward_type_t<T, float>* m_score;         // (score)
      Allen::forward_type_t<T, float>* m_dists;         // (x0, u1[MaxNumUVHits], v2[MaxNumUVHits])

      // Constructor
      __device__ FindHits_OutputTable_t(T* memory) :
        m_hits(reinterpret_cast<Allen::forward_type_t<T, unsigned>*>(memory)),
        m_extrapolation(reinterpret_cast<Allen::forward_type_t<T, float>*>(
          memory + (sizeof(unsigned) * (2 + 2 * MaxNumUVHits)) * NumRow)),
        m_score(reinterpret_cast<Allen::forward_type_t<T, float>*>(
          memory + (sizeof(unsigned) * (2 + 2 * MaxNumUVHits) + sizeof(float) * 6) * NumRow)),
        m_dists(reinterpret_cast<Allen::forward_type_t<T, float>*>(
          memory + (sizeof(unsigned) * (2 + 2 * MaxNumUVHits) + sizeof(float) * 7) * NumRow))
      {}

      __device__ inline auto& tx(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_extrapolation[idx];
      }

      __device__ inline auto& ty(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_extrapolation[idx + NumRow];
      }

      __device__ inline auto& xMagnet(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_extrapolation[idx + NumRow * 2];
      }

      __device__ inline auto& yMagnet(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_extrapolation[idx + NumRow * 3];
      }

      __device__ inline auto& zMagnet(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_extrapolation[idx + NumRow * 4];
      }

      __device__ inline auto& qop(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_extrapolation[idx + NumRow * 5];
      }

      __device__ inline auto& x0_hit(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_hits[idx];
      }

      __device__ inline auto& x3_hit(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_hits[idx + NumRow];
      }

      __device__ inline auto& uv_hit(const unsigned idx, const unsigned layer, const unsigned candidate = 0)
      {
        assert(idx < NumRow);
        assert(layer < 3 && layer > 0);
        assert(candidate < MaxNumUVHits);
        return m_hits[idx + NumRow * (2 + (layer - 1) * MaxNumUVHits + candidate)];
      }

      __device__ inline auto& x0_dist(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_dists[idx];
      }

      __device__ inline auto& uv_dist(const unsigned idx, const unsigned layer, const unsigned candidate = 0)
      {
        assert(idx < NumRow);
        assert(layer < 3 && layer > 0);
        assert(candidate < MaxNumUVHits);
        return m_dists[idx + NumRow * (1 + (layer - 1) * MaxNumUVHits + candidate)];
      }

      __device__ inline auto& score(const unsigned idx)
      {
        assert(idx < NumRow);
        return m_score[idx];
      }

      __device__ inline auto& hit(const unsigned idx, const unsigned layer)
      {
        assert(idx < NumRow);
        assert(layer < 4);
        switch (layer) {
        case 0: return x0_hit(idx);
        case 3: return x3_hit(idx);
        default: return uv_hit(idx, layer);
        }
      }
    };

    using FindHits_OutputTable = FindHits_OutputTable_t<char>;
    using FindHits_OutputTable_Const = FindHits_OutputTable_t<const char>;
  } // namespace DownstreamStructs
} // namespace Downstream