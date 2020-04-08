#pragma once

#include <stdint.h>
#include "CudaCommon.h"
#include "VeloDefinitions.cuh"

namespace Velo {
  struct Module {
    uint hit_start;
    uint hit_num;
    float z;

    __device__ Module() {}
    __device__ Module(const uint param_hit_start, const uint param_hit_num, const float param_z) :
      hit_start(param_hit_start), hit_num(param_hit_num), z(param_z)
    {}
  };

  struct HitBase { // 3 * 4 = 16 B
    float x;
    float y;
    float z;

    __device__ HitBase() {}

    __device__ HitBase(const float _x, const float _y, const float _z) : x(_x), y(_y), z(_z) {}
  };

  struct Hit : public HitBase { // 4 * 4 = 16 B
    uint LHCbID;

    __device__ Hit() {}

    __device__ Hit(const float _x, const float _y, const float _z, const uint _LHCbID) :
      HitBase(_x, _y, _z), LHCbID(_LHCbID)
    {}
  };

  /**
   * @brief TrackletHits struct
   */
  struct TrackletHits { // 3 * 2 = 7 B
    uint16_t hits[3];

    __device__ TrackletHits() {}

    __device__ TrackletHits(const uint16_t h0, const uint16_t h1, const uint16_t h2)
    {
      hits[0] = h0;
      hits[1] = h1;
      hits[2] = h2;
    }
  };

  /* Structure containing indices to hits within hit array */
  struct TrackHits { // 1 + 26 * 2 = 53 B
    uint16_t hits[Velo::Constants::max_track_size];
    uint8_t hitsNum = 3;

    __device__ TrackHits() {}

    __device__ TrackHits(const uint16_t _h0, const uint16_t _h1, const uint16_t _h2)
    {
      hits[0] = _h0;
      hits[1] = _h1;
      hits[2] = _h2;
    }

    __device__ TrackHits(const TrackletHits& tracklet)
    {
      hits[0] = tracklet.hits[0];
      hits[1] = tracklet.hits[1];
      hits[2] = tracklet.hits[2];
    }
  };

  /**
   * @brief Structure to save final track
   * Contains information needed later on in the HLT chain
   * and / or for truth matching.
   */
  struct Track { // 4 + 26 * 16 = 420 B
    bool backward;
    uint8_t hitsNum;
    Hit hits[Velo::Constants::max_track_size];

    __device__ Track() { hitsNum = 0; }

    __device__ void addHit(const Hit& _h)
    {
      hits[hitsNum] = _h;
      hitsNum++;
    }
  };

  /**
   * @brief Means square fit parameters
   *        required for Kalman fit (Velo)
   */
  struct TrackFitParameters {
    float tx, ty;
    bool backward;
  };

  /**
   * @brief Structure to access VELO clusters.
   */
  constexpr uint velo_cluster_size = 3 * sizeof(half_t) + sizeof(uint32_t);
  template<typename T>
  struct Clusters_t {
  protected:
    typename ForwardType<T, half_t>::t* m_base_pointer;
    const uint m_total_number_of_hits;
    const uint m_offset;

  public:
    constexpr static uint element_size = sizeof(uint) + 3 * sizeof(half_t);
    constexpr static uint offset_half_t = sizeof(uint) / sizeof(half_t);

    __host__ __device__
    Clusters_t(T* base_pointer, const uint total_estimated_number_of_clusters, const uint offset = 0) :
      m_base_pointer(reinterpret_cast<typename ForwardType<T, half_t>::t*>(base_pointer)),
      m_total_number_of_hits(total_estimated_number_of_clusters), m_offset(offset)
    {}

    __host__ __device__ Clusters_t(const Clusters_t<T>& clusters) :
      m_base_pointer(clusters.m_base_pointer), m_total_number_of_hits(clusters.m_total_number_of_hits),
      m_offset(clusters.m_offset)
    {}

    // Accessors and lvalue references for all types
    __host__ __device__ uint id(const uint index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[m_offset + index];
    }

    __host__ __device__ void set_id(const uint index, const uint value)
    {
      assert(m_offset + index < m_total_number_of_hits);
      reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[m_offset + index] = value;
    }

    __host__ __device__ float x(const uint index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return static_cast<typename ForwardType<T, float>::t>(
        m_base_pointer[offset_half_t * m_total_number_of_hits + 3 * (m_offset + index)]);
    }

    __host__ __device__ void set_x(const uint index, const half_t value)
    {
      assert(m_offset + index < m_total_number_of_hits);
      m_base_pointer[offset_half_t * m_total_number_of_hits + 3 * (m_offset + index)] = value;
    }

    __host__ __device__ float y(const uint index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return static_cast<typename ForwardType<T, float>::t>(
        m_base_pointer[offset_half_t * m_total_number_of_hits + 3 * (m_offset + index) + 1]);
    }

    __host__ __device__ void set_y(const uint index, const half_t value)
    {
      assert(m_offset + index < m_total_number_of_hits);
      m_base_pointer[offset_half_t * m_total_number_of_hits + 3 * (m_offset + index) + 1] = value;
    }

    __host__ __device__ float z(const uint index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return static_cast<typename ForwardType<T, float>::t>(
        m_base_pointer[offset_half_t * m_total_number_of_hits + 3 * (m_offset + index) + 2]);
    }

    __host__ __device__ void set_z(const uint index, const half_t value)
    {
      assert(m_offset + index < m_total_number_of_hits);
      m_base_pointer[offset_half_t * m_total_number_of_hits + 3 * (m_offset + index) + 2] = value;
    }
  };

  typedef const Clusters_t<const char> ConstClusters;
  typedef Clusters_t<char> Clusters;
} // namespace Velo
