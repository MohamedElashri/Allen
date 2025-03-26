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

namespace UTHitCache::details {
  template<typename, typename = void>
  struct has_isNotYCompatible : std::false_type {
  };
  template<typename T>
  struct has_isNotYCompatible<T, std::void_t<decltype(&T::isNotYCompatible)>> : std::true_type {
  };

  template<typename T>
  __device__ __host__ inline int lower_bound_at_x(T arr[], int start, int end, float target)
  {
    int left = start, right = end;
    while (left < right) {
      int mid = left + (right - left) / 2;
      if (arr[mid].x < target) {
        left = mid + 1;
      }
      else {
        right = mid;
      }
    }
    return left;
  }

  template<typename T>
  __device__ __host__ inline int lower_bound_at_x_x(T arr[], int start, int end, float target)
  {
    int left = start, right = end;
    while (left < right) {
      int mid = left + (right - left) / 2;
      if (__half2float(arr[mid].x.x) < target) {
        left = mid + 1;
      }
      else {
        right = mid;
      }
    }
    return left;
  }

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
} // namespace UTHitCache::details

// Cache
namespace UTHitCache {
  // Cache full UT hit information with 8 Bytes
  // x0, z0, yMin, yMax, dxdy
  template<unsigned N>
  struct FullHitCache_8Bytes {
    //
    // Define Hit struct
    //
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

//
// Define cache
//
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
    __device__ FullHitCache_8Bytes(ElementType* shared_memory) : m_data(shared_memory) {}

    // Constants
    __device__ inline float mean_dxDy() const { return m_mean_dxDy; }
    __device__ inline float mean_z() const { return m_mean_z; }
    __device__ inline auto HitOffset() const { return m_layer_offset; }

    // Cache layer
    __device__ inline auto cache_layer(
      const UT::HitOffsets& ut_hit_offsets,
      const UT::ConstHits& ut_hits,
      const UT::Constants::UTLayerGeometry* layer_info,
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
      m_mean_dxDy = layer_info->mean_dxdy[layer];
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
        details::set_last_bits(element_data.w, dy_idx);
#else
        element_data.x =
          __float22half2_rn(float2 {ut_hits.xAtYEq0(global_idx), ut_hits.zAtYEq0(global_idx) - m_mean_z});
        element_data.y = __float22half2_rn(float2 {ut_hits.yMid(global_idx), ut_hits.dxDy(global_idx) - m_mean_dxDy});
        details::set_last_bits(element_data.y, dy_idx);
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
        out.HalfDy() = m_mean_half_dy[details::get_last_bits(element_data.w)];
        details::set_last_bits(element_data.w, 0);
        out.dxDy() = element_data.w;
#else
        float2 first = __half22float2(element_data.x);
        float2 second = __half22float2(element_data.y);
        out.xAtYEq0() = first.x;
        out.zAtYEq0() = first.y + m_mean_z;
        out.yMid() = second.x;
        out.HalfDy() = m_mean_half_dy[details::get_last_bits(element_data.y)];
        details::set_last_bits(element_data.y, 0);
        out.dxDy() = second.y + m_mean_dxDy;
#endif
      }
      return out;
    }

    template<typename F>
    __device__ inline void for_each_in_x_tol(ushort hit_start, ushort hit_end, float xmin, float xmax, F const& func)
    {
      int first_hit;
      if (m_ut_hits) {
        first_hit =
          binary_search_leftmost(m_ut_hits->xAtYEq0_p(m_layer_offset) + hit_start, hit_end - hit_start, xmin) +
          hit_start;
      }
      else {
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
        first_hit = details::lower_bound_at_x(m_data, hit_start, hit_end, xmin);
#else
        first_hit = details::lower_bound_at_x_x(m_data, hit_start, hit_end, xmin);
#endif
      }
      // if (first_hit < 0) return;
      for (int i = first_hit; i < hit_end; i++) {
        auto h = hit(i);
        if (h.xAtYEq0() > xmax) break;
        func(i, h);
      }
    }
  };

} // namespace UTHitCache
namespace UTHitCache {

  // Cache partial UT hit information with 8 Bytes
  // x0, z0, dxdy
  template<unsigned N>
  struct PartHitCache_8Bytes {

    //
    // Define Hit
    //
    struct MiniHit {
    private:
      float m_xAtYEq0;
      float m_zAtYEq0;
      float m_dxDy;

    public:
      __device__ inline float& xAtYEq0() { return m_xAtYEq0; }
      __device__ inline float& zAtYEq0() { return m_zAtYEq0; }
      __device__ inline float& dxDy() { return m_dxDy; }

    public:
      __device__ inline float xAtYEq0() const { return m_xAtYEq0; }
      __device__ inline float zAtYEq0() const { return m_zAtYEq0; }
      __device__ inline float dxDy() const { return m_dxDy; }

    public:
      __device__ inline float xAt(const float y) const { return xAtYEq0() + y * dxDy(); }

    public:
      __device__ inline bool isYCompatible(const float, const float) const { return true; }
      __device__ inline bool isNotYCompatible(const float, const float) const { return false; }
    };

    //
    // Define cache
    //
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
    using ElementType = float3;
#else
    struct __align__(8) ElementType
    {
      float x;
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
    float m_mean_dxdy, m_mean_z;

    // Constructor
    __device__ PartHitCache_8Bytes(ElementType* shared_memory) : m_data(shared_memory) {}

    // Constants
    __device__ inline float mean_dxdy() const { return m_mean_dxdy; }
    __device__ inline float mean_z() const { return m_mean_z; }
    __device__ inline auto HitOffset() const { return m_layer_offset; }

    // Cache layer
    __device__ inline auto cache_layer(
      const UT::HitOffsets& ut_hit_offsets,
      const UT::ConstHits& ut_hits,
      const UT::Constants::UTLayerGeometry* layer_info,
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
      m_mean_dxdy = layer_info->mean_dxdy[layer];
      m_mean_z = layer_info->mean_z[layer];

      // Fill all hits
      for (unsigned hit_idx = threadIdx.x; hit_idx < layer_number_of_hits; hit_idx += blockDim.x) {
        const unsigned short global_idx = m_layer_offset + hit_idx;

        ElementType element_data;

#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
        element_data.x = ut_hits.xAtYEq0(global_idx);
        element_data.y = ut_hits.zAtYEq0(global_idx);
        element_data.z = ut_hits.dxDy(global_idx);
#else
        element_data.x = ut_hits.xAtYEq0(global_idx);
        element_data.y =
          __float22half2_rn(float2 {ut_hits.zAtYEq0(global_idx) - m_mean_z, ut_hits.dxDy(global_idx) - m_mean_dxdy});
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
        out.dxDy() = m_ut_hits->dxDy(global_idx);
      }
      else {
        ElementType element_data = m_data[hit_idx];
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
        // const auto data = m_data[hit_idx];
        out.xAtYEq0() = element_data.x;
        out.zAtYEq0() = element_data.y;
        out.dxDy() = element_data.z;
#else
        // const auto data = m_data[hit_idx];
        const auto data_y = __half22float2(element_data.y);
        out.xAtYEq0() = element_data.x;
        out.zAtYEq0() = data_y.x + m_mean_z;
        out.dxDy() = data_y.y + m_mean_dxdy;
#endif
      }
      return out;
    }

    template<typename F>
    __device__ inline void for_each_in_x_tol(ushort hit_start, ushort hit_end, float xmin, float xmax, F const& func)
    {
      int first_hit;
      if (m_ut_hits) {
        first_hit =
          binary_search_leftmost(m_ut_hits->xAtYEq0_p(m_layer_offset) + hit_start, hit_end - hit_start, xmin) +
          hit_start;
      }
      else {
        first_hit = details::lower_bound_at_x(m_data, hit_start, hit_end, xmin);
      }
      // if (first_hit < 0) return;
      for (int i = first_hit; i < hit_end; i++) {
        auto h = hit(i);
        if (h.xAtYEq0() > xmax) break;
        func(i, h);
      }
    }
  };

} // namespace UTHitCache

namespace UTHitCache {
  // Cache full UT hit information with 8 Bytes
  // x0, z0, yMin, yMax
  template<unsigned N>
  struct NodxDyHitCache_8Bytes {
    //
    // Define Hit struct
    //
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

//
// Define cache
//
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
    using ElementType = float3;
#else
    struct __align__(8) ElementType
    {
      float x;
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
    __device__ NodxDyHitCache_8Bytes(ElementType* shared_memory) : m_data(shared_memory) {}

    // Constants
    __device__ inline float mean_dxDy() const { return m_mean_dxDy; }
    __device__ inline float mean_z() const { return m_mean_z; }
    __device__ inline auto HitOffset() const { return m_layer_offset; }

    // Cache layer
    __device__ inline auto cache_layer(
      const UT::HitOffsets& ut_hit_offsets,
      const UT::ConstHits& ut_hits,
      const UT::Constants::UTLayerGeometry* layer_info,
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
      m_mean_dxDy = layer_info->mean_dxdy[layer];
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
        details::set_last_bits(element_data.z, dy_idx);
#else
        element_data.x = ut_hits.xAtYEq0(global_idx);
        element_data.y = __float22half2_rn(float2 {ut_hits.zAtYEq0(global_idx) - m_mean_z, ut_hits.yMid(global_idx)});
        details::set_last_bits(element_data.y, dy_idx);
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
        out.HalfDy() = m_mean_half_dy[details::get_last_bits(element_data.z)];
        details::set_last_bits(element_data.z, 0);
        out.yMid() = element_data.z;
        out.dxDy() = m_mean_dxDy;
#else
        const auto dy_idx = details::get_last_bits(element_data.y);
        details::set_last_bits(element_data.y, 0);
        float2 second = __half22float2(element_data.y);
        out.xAtYEq0() = element_data.x;
        out.zAtYEq0() = second.x + m_mean_z;
        out.HalfDy() = m_mean_half_dy[dy_idx];
        out.yMid() = second.y;
        out.dxDy() = m_mean_dxDy;
#endif
      }
      return out;
    }

    template<typename F>
    __device__ inline void for_each_in_x_tol(ushort hit_start, ushort hit_end, float xmin, float xmax, F const& func)
    {
      int first_hit;
      if (m_ut_hits) {
        first_hit =
          binary_search_leftmost(m_ut_hits->xAtYEq0_p(m_layer_offset) + hit_start, hit_end - hit_start, xmin) +
          hit_start;
      }
      else {
        first_hit = details::lower_bound_at_x(m_data, hit_start, hit_end, xmin);
      }
      // if (first_hit < 0) return;
      for (int i = first_hit; i < hit_end; i++) {
        auto h = hit(i);
        if (h.xAtYEq0() > xmax) break;
        func(i, h);
      }
    }
  };

} // namespace UTHitCache