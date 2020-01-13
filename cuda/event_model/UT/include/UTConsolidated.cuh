#pragma once

#include "ConsolidatedTypes.cuh"
#include "UTEventModel.cuh"
#include <stdint.h>

namespace UT {
  namespace Consolidated {
    constexpr static uint hits_number_of_arrays = 8;

    template<typename T>
    struct Hits {
    private:
      typename ForwardType<T>::float_t* m_base_pointer;
      const uint m_total_number_of_hits;
      const uint m_track_offset;

    public:
      __host__ __device__ Hits(const Hits& hits) : m_base_pointer(hits.m_base_pointer) {}

      __host__ __device__
      Hits(typename ForwardType<T>::char_t* base_pointer, const uint track_offset, const uint total_number_of_hits) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T>::float_t*>(base_pointer) + track_offset),
        m_total_number_of_hits(total_number_of_hits), m_track_offset(track_offset)
      {}

      // Const and lvalue accessors
      float yBegin(const uint index) const { return m_base_pointer[index]; }

      float& yBegin(const uint index) { return m_base_pointer[index]; }

      float yEnd(const uint index) const { return m_base_pointer[m_total_number_of_hits + index]; }

      float& yEnd(const uint index) { return m_base_pointer[m_total_number_of_hits + index]; }

      float zAtYEq0(const uint index) const { return m_base_pointer[2 * m_total_number_of_hits + index]; }

      float& zAtYEq0(const uint index) { return m_base_pointer[2 * m_total_number_of_hits + index]; }

      float xAtYEq0(const uint index) const { return m_base_pointer[3 * m_total_number_of_hits + index]; }

      float& xAtYEq0(const uint index) { return m_base_pointer[3 * m_total_number_of_hits + index]; }

      float weight(const uint index) const { return m_base_pointer[4 * m_total_number_of_hits + index]; }

      float& weight(const uint index) { return m_base_pointer[4 * m_total_number_of_hits + index]; }

      uint id(const uint index) const
      {
        return reinterpret_cast<typename ForwardType<T>::uint_t*>(m_base_pointer)[5 * m_total_number_of_hits + index];
      }

      uint& id(const uint index)
      {
        return reinterpret_cast<typename ForwardType<T>::uint_t*>(m_base_pointer)[5 * m_total_number_of_hits + index];
      }

      uint8_t plane_code(const uint index) const
      {
        return reinterpret_cast<typename ForwardType<T>::uint_8_t*>(
          m_base_pointer + 6 * m_total_number_of_hits - m_track_offset)[m_track_offset + index];
      }

      uint8_t& plane_code(const uint index)
      {
        return reinterpret_cast<typename ForwardType<T>::uint_8_t*>(
          m_base_pointer + 6 * m_total_number_of_hits - m_track_offset)[m_track_offset + index];
      }

      __host__ __device__ void set(const uint hit_number, const UT::Hit& hit)
      {
        yBegin(hit_number) = hit.yBegin;
        yEnd(hit_number) = hit.yEnd;
        zAtYEq0(hit_number) = hit.zAtYEq0;
        xAtYEq0(hit_number) = hit.xAtYEq0;
        weight(hit_number) = hit.weight;
        id(hit_number) = hit.LHCbID;
        plane_code(hit_number) = hit.plane_code;
      }

      __host__ __device__ UT::Hit get(const uint hit_number) const
      {
        return UT::Hit {yBegin(hit_number),
                        yEnd(hit_number),
                        zAtYEq0(hit_number),
                        xAtYEq0(hit_number),
                        weight(hit_number),
                        id(hit_number),
                        plane_code(hit_number)};
      }
    };

    //-------------------------------------------
    // Struct for holding VELO track information.
    //-------------------------------------------
    template<typename T>
    struct Tracks : public ::Consolidated::Tracks {
    private:
      // Indices of associated VELO tracks.
      typename ForwardType<T>::uint_t* m_velo_track;
      // Array of q/p for each track.
      typename ForwardType<T>::float_t* m_qop;

    public:
      __host__ __device__ Tracks(
        const uint* atomics_base_pointer,
        const uint* track_hit_number_base_pointer,
        typename ForwardType<T>::float_t* qop_base_pointer,
        typename ForwardType<T>::uint_t* velo_track_base_pointer,
        const uint current_event_number,
        const uint number_of_events) :
        ::Consolidated::Tracks(
          atomics_base_pointer,
          track_hit_number_base_pointer,
          current_event_number,
          number_of_events),
        m_velo_track(velo_track_base_pointer + tracks_offset(current_event_number)),
        m_qop(qop_base_pointer + tracks_offset(current_event_number))
      {}

      __host__ __device__ uint velo_track(const uint index) const { return m_velo_track[index]; }

      __host__ __device__ uint& velo_track(const uint index) { return m_velo_track[index]; }

      __host__ __device__ float qop(const uint index) const { return m_qop[index]; }

      __host__ __device__ float& qop(const uint index) { return m_qop[index]; }

      __host__ __device__ Hits<T> get_hits(typename ForwardType<T>::char_t* hits_base_pointer, const uint track_number)
        const
      {
        return Hits<T> {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }
    };

  } // end namespace Consolidated
} // end namespace UT
