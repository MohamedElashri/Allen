/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <ostream>
#include <iomanip>
#include "UTDefinitions.cuh"
#include "VeloConsolidated.cuh"
#include "VeloEventModel.cuh"

namespace UT {
  // Hit base containing just the geometrical information about the hit.
  struct Hit {
    float yBegin;
    float yEnd;
    float zAtYEq0;
    float xAtYEq0;
    float dxDy;
    float weight;
    uint32_t LHCbID;
    uint8_t plane_code;

    __device__ Hit() {}

    __device__ Hit(
      const float _yBegin,
      const float _yEnd,
      const float _zAtYEq0,
      const float _xAtYEq0,
      const float _dxDy,
      const float _weight,
      const uint32_t _LHCbID,
      const uint8_t _plane_code) :
      yBegin(_yBegin),
      yEnd(_yEnd), zAtYEq0(_zAtYEq0), xAtYEq0(_xAtYEq0), dxDy(_dxDy), weight(_weight), LHCbID(_LHCbID),
      plane_code(_plane_code)
    {}

    bool operator==(const Hit& h) const { return LHCbID == h.LHCbID; }

    bool operator!=(const Hit& h) const { return !operator==(h); }

    friend std::ostream& operator<<(std::ostream& stream, const Hit& ut_hit)
    {
      constexpr int prec = 6, width = 12;
      stream << std::setprecision(prec) << std::setw(width) << "UT hit" << std::setw(width) << ut_hit.LHCbID
             << std::setw(width) << ut_hit.yBegin << std::setw(width) << ut_hit.yEnd << std::setw(width)
             << ut_hit.zAtYEq0 << std::setw(width) << ut_hit.xAtYEq0 << std::setw(width) << ut_hit.weight
             << std::setw(width) << ut_hit.plane_code;
      return stream;
    }
  };

  struct TrackHits {
    float qop;
    float x, z;
    float tx;
    unsigned short hits_num = 0;
    unsigned short velo_track_index;
    short hits[UT::Constants::max_track_size];

    friend std::ostream& operator<<(std::ostream& stream, const TrackHits& hit)
    {
      constexpr int prec = 6, width = 12;
      stream << std::setprecision(prec) << std::setw(width) << "UT track" << std::setw(width) << hit.qop
             << std::setw(width) << hit.x << std::setw(width) << hit.z << std::setw(width) << hit.tx << std::setw(width)
             << hit.hits_num;
      return stream;
    }
  };

  struct DownstreamTrack {
  public:
    constexpr static unsigned n_layers = UT::Constants::n_layers;
    float x, y, tx, ty, qop, chi2, ghost_prob;
    ushort scifi_idx;
    ushort num_hits;
    ushort hits[n_layers];
  };

  /**
   * @brief Offset and number of hits of each layer.
   */
  struct HitOffsets {
    const unsigned* m_ut_hit_offsets;

    __device__ __host__ HitOffsets(const unsigned* base_pointer, const unsigned event_number) :
      m_ut_hit_offsets(base_pointer + event_number * UT::Constants::n_groups)
    {}

    __device__ __host__ unsigned sector_group_offset(const unsigned sector_group) const
    {
      assert(sector_group <= UT::Constants::n_groups);
      return m_ut_hit_offsets[sector_group];
    }

    __device__ __host__ unsigned sector_group_number_of_hits(const unsigned sector_group) const
    {
      assert(sector_group < UT::Constants::n_groups);
      return sector_group_offset(sector_group + 1) - sector_group_offset(sector_group);
    }

    __device__ __host__ unsigned sector_group_offset(const unsigned layer, const unsigned sector_group) const
    {
      assert(sector_group <= UT::Constants::n_groups_in_layer);
      return m_ut_hit_offsets[layer * UT::Constants::n_groups_in_layer + sector_group];
    }

    __device__ __host__ unsigned sector_group_number_of_hits(const unsigned layer_number, const unsigned sector_group)
      const
    {
      assert(layer_number < 4);
      assert(sector_group < UT::Constants::n_groups_in_layer);
      return sector_group_offset(layer_number, sector_group + 1) - sector_group_offset(layer_number, sector_group);
    }

    __device__ __host__ unsigned layer_offset(const unsigned layer_number) const
    {
      assert(layer_number <= 4);
      return m_ut_hit_offsets[layer_number * UT::Constants::n_groups_in_layer];
    }

    __device__ __host__ unsigned layer_number_of_hits(const unsigned layer_number) const
    {
      assert(layer_number < 4);
      return layer_offset(layer_number + 1) - layer_offset(layer_number);
    }

    __device__ __host__ unsigned event_offset() const { return m_ut_hit_offsets[0]; }

    __device__ __host__ unsigned event_number_of_hits() const
    {
      return m_ut_hit_offsets[UT::Constants::n_groups] - event_offset();
    }
  };

  /*
     SoA for hit variables
     The hits for every layer are written behind each other, the offsets
     are stored for access;
     one Hits structure exists per event
  */
  template<typename T>
  struct Hits_t {
  protected:
    typename ForwardType<T, float>::t* m_base_pointer;
    const unsigned m_total_number_of_hits;
    const unsigned m_offset;

  public:
    constexpr static unsigned element_size = 6 * sizeof(float) + sizeof(unsigned);
    /**
     * @brief Populates the UTHits object pointers to an array of data
     *        pointed by base_pointer.
     */
    __host__ __device__ Hits_t(T* base_pointer, const unsigned total_number_of_hits, const unsigned offset = 0) :
      m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer)),
      m_total_number_of_hits(total_number_of_hits), m_offset(offset)
    {}

    // Const and lvalue accessors
    __host__ __device__ float yBegin(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + index];
    }

    __host__ __device__ inline float& yBegin(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + index];
    }

    __host__ __device__ inline float yEnd(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + m_total_number_of_hits + index];
    }

    __host__ __device__ inline float& yEnd(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + m_total_number_of_hits + index];
    }

    __host__ __device__ inline float zAtYEq0(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 2 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline float& zAtYEq0(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 2 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline float xAtYEq0(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 3 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline float& xAtYEq0(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 3 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline const float* xAtYEq0_p(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer + (m_offset + 3 * m_total_number_of_hits + index);
    }

    __host__ __device__ inline float dxDy(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 4 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline float& dxDy(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 4 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline float weight(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 5 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline float& weight(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + 5 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline unsigned id(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, unsigned>::t*>(
        m_base_pointer)[m_offset + 6 * m_total_number_of_hits + index];
    }

    __host__ __device__ inline unsigned& id(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, unsigned>::t*>(
        m_base_pointer)[m_offset + 6 * m_total_number_of_hits + index];
    }

    /**
     * @brief Gets a hit in the UT::Hit format from the global hit index.
     */
    __host__ __device__ inline Hit getHit(const unsigned index) const
    {
      return {yBegin(index), yEnd(index), zAtYEq0(index), xAtYEq0(index), dxDy(index), weight(index), id(index), 0};
    }

    __host__ __device__ inline bool isYCompatible(const unsigned index, const float y, const float tol) const
    {
      return yMin(index) - tol <= y && y <= yMax(index) + tol;
    }

    __host__ __device__ inline bool isNotYCompatible(const unsigned index, const float y, const float tol) const
    {
      return yMin(index) - tol > y || y > yMax(index) + tol;
    }

    __host__ __device__ inline float cosT(const unsigned index) const
    {
      return (fabsf(xAtYEq0(index)) < 1.0e-9f) ? 1.f / sqrtf(1.f + dxDy(index) * dxDy(index)) : cosf(dxDy(index));
    }

    __host__ __device__ inline float sinT(const unsigned index) const { return tanT(index) * cosT(index); }

    __host__ __device__ inline float tanT(const unsigned index) const { return -1.f * dxDy(index); }

    __host__ __device__ inline float xAt(const unsigned index, const float globalY) const
    {
      return xAtYEq0(index) + globalY * dxDy(index);
    }

    __host__ __device__ inline float yMax(const unsigned index) const { return fmaxf(yBegin(index), yEnd(index)); }

    __host__ __device__ inline float yMid(const unsigned index) const { return 0.5f * (yBegin(index) + yEnd(index)); }

    __host__ __device__ inline float yMin(const unsigned index) const { return fminf(yBegin(index), yEnd(index)); }

    // Pointer accessors for binary search
    __host__ __device__ inline typename ForwardType<T, float>::t* yBegin_p(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer + m_offset + index;
    }

    __host__ __device__ inline typename ForwardType<T, float>::t* yEnd_p(const unsigned index) const
    {
      assert(m_offset + index <= m_total_number_of_hits);
      return m_base_pointer + m_offset + m_total_number_of_hits + index;
    }
  };

  typedef const Hits_t<const char> ConstHits;
  typedef Hits_t<char> Hits;

  /**
   * @brief Pre decoded hits datatype
   * @details This datatype is used for the predecoding steps of the UT.
   */
  template<typename T>
  struct PreDecodedHits_t {
  private:
    typename ForwardType<T, unsigned>::t* m_base_pointer;
    const unsigned m_total_number_of_hits;

  public:
    constexpr static unsigned element_size = 2 * sizeof(unsigned) + sizeof(float);

    /**
     * @brief Populates the UTHits object pointers to an array of data
     *        pointed by base_pointer.
     */
    __host__ __device__ PreDecodedHits_t(T* base_pointer, const unsigned total_number_of_hits) :
      m_base_pointer(reinterpret_cast<typename ForwardType<T, unsigned>::t*>(base_pointer)),
      m_total_number_of_hits(total_number_of_hits)
    {}

    // Const and lvalue accessors
    __host__ __device__ unsigned geometry_index(const unsigned index) const
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[index];
    }

    __host__ __device__ unsigned& geometry_index(const unsigned index)
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[index];
    }

    __host__ __device__ unsigned id(const unsigned index) const
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[m_total_number_of_hits + index];
    }

    __host__ __device__ unsigned& id(const unsigned index)
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[m_total_number_of_hits + index];
    }

    __host__ __device__ float num_strips(const unsigned index) const
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer)[2 * m_total_number_of_hits + index];
    }

    __host__ __device__ float& num_strips(const unsigned index)
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer)[2 * m_total_number_of_hits + index];
    }
  };

  typedef const PreDecodedHits_t<const char> ConstPreDecodedHits;
  typedef PreDecodedHits_t<char> PreDecodedHits;
} // namespace UT
