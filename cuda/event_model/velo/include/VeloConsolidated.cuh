#pragma once

#include <stdint.h>
#include <cassert>
#include "States.cuh"
#include "VeloEventModel.cuh"
#include "ConsolidatedTypes.cuh"
#include "CudaCommon.h"

namespace Velo {
  namespace Consolidated {
    /**
     * @brief Structure to access VELO hits.
     */
    template<typename T>
    struct Hits_t {
    private:
      typename ForwardType<T, float>::t* m_base_pointer;
      const uint m_total_number_of_hits;

    public:
      __host__ __device__ Hits_t(T* base_pointer, const uint track_offset, const uint total_number_of_hits) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer) + track_offset),
        m_total_number_of_hits(total_number_of_hits)
      {}

      __host__ __device__ Hits_t(const Hits_t<T>& hits) :
        m_base_pointer(hits.m_base_pointer), m_total_number_of_hits(hits.m_total_number_of_hits)
      {}

      // Accessors and lvalue references for all types
      __host__ __device__ float x(const uint index) const { return m_base_pointer[index]; }

      __host__ __device__ float& x(const uint index) { return m_base_pointer[index]; }

      __host__ __device__ float y(const uint index) const { return m_base_pointer[m_total_number_of_hits + index]; }

      __host__ __device__ float& y(const uint index) { return m_base_pointer[m_total_number_of_hits + index]; }

      __host__ __device__ float z(const uint index) const { return m_base_pointer[2 * m_total_number_of_hits + index]; }

      __host__ __device__ float& z(const uint index) { return m_base_pointer[2 * m_total_number_of_hits + index]; }

      __host__ __device__ uint id(const uint index) const
      {
        return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[3 * m_total_number_of_hits + index];
      }

      __host__ __device__ uint& id(const uint index)
      {
        return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[3 * m_total_number_of_hits + index];
      }

      __host__ __device__ void set(const uint hit_number, const Velo::Hit& hit)
      {
        x(hit_number) = hit.x;
        y(hit_number) = hit.y;
        z(hit_number) = hit.z;
        id(hit_number) = hit.LHCbID;
      }

      __host__ __device__ Velo::Hit get(const uint hit_number) const
      {
        return Velo::Hit {x(hit_number), y(hit_number), z(hit_number), id(hit_number)};
      }
    };

    typedef const Hits_t<const char> ConstHits;
    typedef Hits_t<char> Hits;

    struct Tracks : public ::Consolidated::Tracks {
      __host__ __device__ Tracks(
        const uint* atomics_base_pointer,
        const uint* track_hit_number_base_pointer,
        const uint current_event_number,
        const uint number_of_events) :
        ::Consolidated::Tracks(
          atomics_base_pointer,
          track_hit_number_base_pointer,
          current_event_number,
          number_of_events)
      {}

      template<typename T>
      __host__ __device__ Hits_t<typename ForwardType<T, char>::t> get_hits(
        T* hits_base_pointer,
        const uint track_number) const
      {
        return Hits_t<typename ForwardType<T, char>::t> {
          hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }
    };

    template<typename T>
    struct States_t {
    private:
      typename ForwardType<T, float>::t* m_base_pointer;
      const uint m_total_number_of_tracks;

    public:
      __host__ __device__ States_t(typename ForwardType<T, char>::t* base_pointer, const uint total_number_of_tracks) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer)),
        m_total_number_of_tracks(total_number_of_tracks)
      {}

      __host__ __device__ States_t(const States_t<T>& states) :
        m_base_pointer(states.m_base_pointer), m_total_number_of_tracks(states.m_total_number_of_tracks)
      {}

      // Accessors and lvalue references for all types
      __host__ __device__ float x(const uint index) const { return m_base_pointer[index]; }

      __host__ __device__ float& x(const uint index) { return m_base_pointer[index]; }

      __host__ __device__ float y(const uint index) const { return m_base_pointer[m_total_number_of_tracks + index]; }

      __host__ __device__ float& y(const uint index) { return m_base_pointer[m_total_number_of_tracks + index]; }

      __host__ __device__ float tx(const uint index) const
      {
        return m_base_pointer[2 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& tx(const uint index) { return m_base_pointer[2 * m_total_number_of_tracks + index]; }

      __host__ __device__ float ty(const uint index) const
      {
        return m_base_pointer[3 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& ty(const uint index) { return m_base_pointer[3 * m_total_number_of_tracks + index]; }

      __host__ __device__ float z(const uint index) const
      {
        return m_base_pointer[4 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& z(const uint index) { return m_base_pointer[4 * m_total_number_of_tracks + index]; }

      __host__ __device__ bool backward(const uint index) const
      {
        return reinterpret_cast<typename ForwardType<T, bool>::t*>(
          m_base_pointer)[5 * m_total_number_of_tracks + index];
      }

      __host__ __device__ bool& backward(const uint index)
      {
        return reinterpret_cast<typename ForwardType<T, bool>::t*>(
          m_base_pointer)[5 * m_total_number_of_tracks + index];
      }

      __host__ __device__ void set(const uint track_number, const VeloState& state)
      {
        x(track_number) = state.x;
        y(track_number) = state.y;
        tx(track_number) = state.tx;
        ty(track_number) = state.ty;
        z(track_number) = state.z;
        backward(track_number) = state.backward;
      }

      __host__ __device__ VeloState get(const uint track_number) const
      {
        VeloState state;

        state.x = x(track_number);
        state.y = y(track_number);
        state.tx = tx(track_number);
        state.ty = ty(track_number);
        state.z = z(track_number);
        state.backward = backward(track_number);

        return state;
      }

      __host__ __device__ MiniState getMiniState(const uint track_number) const
      {
        MiniState state;

        state.x = x(track_number);
        state.y = y(track_number);
        state.tx = tx(track_number);
        state.ty = ty(track_number);
        state.z = z(track_number);

        return state;
      }
    };

    typedef const States_t<const char> ConstStates;
    typedef States_t<char> States;

    template<typename T>
    struct KalmanStates_t {
    private:
      typename ForwardType<T, float>::t* m_base_pointer;
      const uint m_total_number_of_tracks;

    public:
      __host__ __device__ KalmanStates_t(T* base_pointer, const uint total_number_of_tracks) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer)),
        m_total_number_of_tracks(total_number_of_tracks)
      {}

      __host__ __device__ KalmanStates_t(const KalmanStates_t<T>& states) :
        m_base_pointer(states.m_base_pointer), m_total_number_of_tracks(states.m_total_number_of_tracks)
      {}

      // Accessors and lvalue references for all types
      __host__ __device__ float x(const uint index) const { return m_base_pointer[index]; }

      __host__ __device__ float& x(const uint index) { return m_base_pointer[index]; }

      __host__ __device__ float y(const uint index) const { return m_base_pointer[m_total_number_of_tracks + index]; }

      __host__ __device__ float& y(const uint index) { return m_base_pointer[m_total_number_of_tracks + index]; }

      __host__ __device__ float tx(const uint index) const
      {
        return m_base_pointer[2 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& tx(const uint index) { return m_base_pointer[2 * m_total_number_of_tracks + index]; }

      __host__ __device__ float ty(const uint index) const
      {
        return m_base_pointer[3 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& ty(const uint index) { return m_base_pointer[3 * m_total_number_of_tracks + index]; }

      __host__ __device__ float c00(const uint index) const
      {
        return m_base_pointer[4 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c00(const uint index) { return m_base_pointer[4 * m_total_number_of_tracks + index]; }

      __host__ __device__ float c20(const uint index) const
      {
        return m_base_pointer[5 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c20(const uint index) { return m_base_pointer[5 * m_total_number_of_tracks + index]; }

      __host__ __device__ float c22(const uint index) const
      {
        return m_base_pointer[6 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c22(const uint index) { return m_base_pointer[6 * m_total_number_of_tracks + index]; }

      __host__ __device__ float c11(const uint index) const
      {
        return m_base_pointer[7 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c11(const uint index) { return m_base_pointer[7 * m_total_number_of_tracks + index]; }

      __host__ __device__ float c31(const uint index) const
      {
        return m_base_pointer[8 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c31(const uint index) { return m_base_pointer[8 * m_total_number_of_tracks + index]; }

      __host__ __device__ float c33(const uint index) const
      {
        return m_base_pointer[9 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c33(const uint index) { return m_base_pointer[9 * m_total_number_of_tracks + index]; }

      __host__ __device__ float z(const uint index) const
      {
        return m_base_pointer[10 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& z(const uint index) { return m_base_pointer[10 * m_total_number_of_tracks + index]; }

      __device__ __host__ void set(const uint track_number, const KalmanVeloState& state)
      {
        x(track_number) = state.x;
        y(track_number) = state.y;
        tx(track_number) = state.tx;
        ty(track_number) = state.ty;

        c00(track_number) = state.c00;
        c20(track_number) = state.c20;
        c22(track_number) = state.c22;
        c11(track_number) = state.c11;
        c31(track_number) = state.c31;
        c33(track_number) = state.c33;

        z(track_number) = state.z;
      }

      __device__ __host__ KalmanVeloState get(const uint track_number) const
      {
        KalmanVeloState state;

        state.x = x(track_number);
        state.y = y(track_number);
        state.tx = tx(track_number);
        state.ty = ty(track_number);

        state.c00 = c00(track_number);
        state.c20 = c20(track_number);
        state.c22 = c22(track_number);
        state.c11 = c11(track_number);
        state.c31 = c31(track_number);
        state.c33 = c33(track_number);

        state.z = z(track_number);

        return state;
      }
    };

    typedef const KalmanStates_t<const char> ConstKalmanStates;
    typedef KalmanStates_t<char> KalmanStates;
  } // namespace Consolidated
} // namespace Velo
