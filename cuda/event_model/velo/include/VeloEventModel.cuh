#pragma once

#include <stdint.h>
#include "CudaCommon.h"
#include "VeloDefinitions.cuh"

namespace Velo {
  struct Module {
    uint hitStart;
    uint hitNums;
    float z;

    __device__ Module() {}
    __device__ Module(const uint _hitStart, const uint _hitNums, const float _z) :
      hitStart(_hitStart), hitNums(_hitNums), z(_z) {}
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
      HitBase(_x, _y, _z), LHCbID(_LHCbID) {}
  };

  /**
   * @brief TrackletHits struct
   */
  struct TrackletHits { // 3 * 2 = 7 B
    uint16_t hits[3];

    __device__ TrackletHits() {}
    
    __device__ TrackletHits(const uint16_t h0, const uint16_t h1, const uint16_t h2) {
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

    __device__ TrackHits(const uint16_t _h0, const uint16_t _h1, const uint16_t _h2) {
      hits[0] = _h0;
      hits[1] = _h1;
      hits[2] = _h2;
    }

    __device__ TrackHits(const TrackletHits& tracklet) {
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

    __device__ void addHit(const Hit& _h) {
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
  template<typename T>
  struct Clusters {
  private:
    // T can either be const uint32_t or uint32_t
    T* m_base_pointer;
    const uint m_total_estimated_number_of_clusters;

  public:
    __host__ __device__ Clusters(T* base_pointer, const uint total_estimated_number_of_clusters) :
      m_base_pointer(base_pointer), m_total_estimated_number_of_clusters(total_estimated_number_of_clusters) {}

    // Accessors and lvalue references for all types
    __host__ __device__ float x(const uint index) const {
      return reinterpret_cast<typename ForwardType<T>::float_t*>(m_base_pointer)[index];
    }

    __host__ __device__ float& x(const uint index) { return reinterpret_cast<float*>(m_base_pointer)[index]; }

    __host__ __device__ float y(const uint index) const {
      return reinterpret_cast<typename ForwardType<T>::float_t*>(
        m_base_pointer)[m_total_estimated_number_of_clusters + index];
    }

    __host__ __device__ float& y(const uint index) {
      return reinterpret_cast<float*>(m_base_pointer)[m_total_estimated_number_of_clusters + index];
    }

    __host__ __device__ float z(const uint index) const {
      return reinterpret_cast<typename ForwardType<T>::float_t*>(
        m_base_pointer)[2 * m_total_estimated_number_of_clusters + index];
    }

    __host__ __device__ float& z(const uint index) {
      return reinterpret_cast<float*>(m_base_pointer)[2 * m_total_estimated_number_of_clusters + index];
    }

    __host__ __device__ uint32_t id(const uint index) const {
      return m_base_pointer[3 * m_total_estimated_number_of_clusters + index];
    }

    __host__ __device__ uint32_t& id(const uint index) {
      return m_base_pointer[3 * m_total_estimated_number_of_clusters + index];
    }
  };
} // namespace Velo
