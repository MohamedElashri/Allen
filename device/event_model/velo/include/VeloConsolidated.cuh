/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include <cassert>
#include "States.cuh"
#include "VeloEventModel.cuh"
#include "ConsolidatedTypes.cuh"
#include "BackendCommon.h"

namespace Velo {
  namespace Consolidated {
    /**
     * @brief Structure to access VELO hits.
     */
    template<typename T>
    struct Hits_t : Velo::Clusters_t<T> {
      using Velo::Clusters_t<T>::m_base_pointer;
      using Velo::Clusters_t<T>::m_total_number_of_hits;
      using Velo::Clusters_t<T>::m_offset;

      __host__ __device__ Hits_t(T* base_pointer, const unsigned offset, const unsigned total_number_of_hits) :
        Velo::Clusters_t<T>(base_pointer, total_number_of_hits, offset)
      {}

      __host__ __device__ Hits_t(const Hits_t<T>& hits) : Velo::Clusters_t<T>(hits) {}

      __host__ __device__ void set(const unsigned index, const Velo::Hit& hit)
      {
        assert(m_offset + index < m_total_number_of_hits);
        this->set_x(index, hit.x);
        this->set_y(index, hit.y);
        this->set_z(index, hit.z);
        this->set_id(index, hit.LHCbID);
      }

      __host__ __device__ Velo::Hit get(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_hits);
        return Velo::Hit {this->x(index), this->y(index), this->z(index), this->id(index)};
      }
    };

    typedef const Hits_t<const char> ConstHits;
    typedef Hits_t<char> Hits;

    struct Tracks : public ::Consolidated::Tracks {
      __host__ __device__ Tracks(
        const unsigned* atomics_base_pointer,
        const unsigned* track_hit_number_base_pointer,
        const unsigned current_event_number,
        const unsigned number_of_events) :
        ::Consolidated::Tracks(
          atomics_base_pointer,
          track_hit_number_base_pointer,
          current_event_number,
          number_of_events)
      {}

      __host__ __device__ ConstHits get_hits(const char* hits_base_pointer, const unsigned track_number) const
      {
        return ConstHits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }

      __host__ __device__ Hits get_hits(char* hits_base_pointer, const unsigned track_number)
      {
        return Hits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }

      __host__ std::vector<unsigned> get_lhcbids_for_track(const char* hits_base_pointer, const unsigned track_number)
        const
      {
        std::vector<unsigned> ids;
        const auto hits = ConstHits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
        for (unsigned i = 0; i < number_of_hits(track_number); ++i) {
          ids.push_back(hits.id(i));
        }
        return ids;
      }
    };

    typedef const Tracks ConstTracks;

    constexpr unsigned states_number_of_arrays = 6;

    template<typename T>
    struct States_t {
    private:
      typename ForwardType<T, float>::t* m_base_pointer;
      const unsigned m_total_number_of_tracks;
      const unsigned m_offset;

    public:
      __host__ __device__ States_t(T* base_pointer, const unsigned total_number_of_tracks, const unsigned offset = 0) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer)),
        m_total_number_of_tracks(total_number_of_tracks), m_offset(offset)
      {}

      __host__ __device__ States_t(const States_t<T>& states) :
        m_base_pointer(states.m_base_pointer), m_total_number_of_tracks(states.m_total_number_of_tracks),
        m_offset(states.m_offset)
      {}

      // Accessors and lvalue references for all types
      __host__ __device__ float x(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + index];
      }

      __host__ __device__ float& x(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + index];
      }

      __host__ __device__ float y(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + m_total_number_of_tracks + index];
      }

      __host__ __device__ float& y(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + m_total_number_of_tracks + index];
      }

      __host__ __device__ float tx(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_tracks);

        return m_base_pointer[m_offset + 2 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& tx(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + 2 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float ty(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_tracks);

        return m_base_pointer[m_offset + 3 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& ty(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + 3 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float z(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + 4 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& z(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return m_base_pointer[m_offset + 4 * m_total_number_of_tracks + index];
      }

      __host__ __device__ bool backward(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return reinterpret_cast<typename ForwardType<T, bool>::t*>(
          m_base_pointer + 5 * m_total_number_of_tracks)[m_offset + index];
      }

      __host__ __device__ bool& backward(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_tracks);
        return reinterpret_cast<typename ForwardType<T, bool>::t*>(
          m_base_pointer + 5 * m_total_number_of_tracks)[m_offset + index];
      }

      __host__ __device__ void set(const unsigned track_number, const VeloState& state)
      {
        x(track_number) = state.x;
        y(track_number) = state.y;
        tx(track_number) = state.tx;
        ty(track_number) = state.ty;
        z(track_number) = state.z;
        backward(track_number) = state.backward;
      }

      __host__ __device__ VeloState get(const unsigned track_number) const
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

      __host__ __device__ MiniState getMiniState(const unsigned track_number) const
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

    constexpr unsigned kalman_states_number_of_arrays = 11;

    template<typename T>
    struct KalmanStates_t {
    private:
      typename ForwardType<T, float>::t* m_base_pointer;
      const unsigned m_total_number_of_tracks;

    public:
      __host__ __device__ KalmanStates_t(T* base_pointer, const unsigned total_number_of_tracks) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer)),
        m_total_number_of_tracks(total_number_of_tracks)
      {}

      __host__ __device__ KalmanStates_t(const KalmanStates_t<T>& states) :
        m_base_pointer(states.m_base_pointer), m_total_number_of_tracks(states.m_total_number_of_tracks)
      {}

      // Accessors and lvalue references for all types
      __host__ __device__ float x(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[index];
      }

      __host__ __device__ float& x(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[index];
      }

      __host__ __device__ float y(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[m_total_number_of_tracks + index];
      }

      __host__ __device__ float& y(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[m_total_number_of_tracks + index];
      }

      __host__ __device__ float tx(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[2 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& tx(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[2 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float ty(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[3 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& ty(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[3 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float c00(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[4 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c00(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[4 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float c20(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[5 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c20(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[5 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float c22(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[6 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c22(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[6 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float c11(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[7 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c11(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[7 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float c31(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[8 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c31(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[8 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float c33(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[9 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& c33(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[9 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float z(const unsigned index) const
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[10 * m_total_number_of_tracks + index];
      }

      __host__ __device__ float& z(const unsigned index)
      {
        assert(index < m_total_number_of_tracks);
        return m_base_pointer[10 * m_total_number_of_tracks + index];
      }

      __device__ __host__ void set(const unsigned track_number, const KalmanVeloState& state)
      {
        assert(track_number < m_total_number_of_tracks);

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

      __device__ __host__ KalmanVeloState get(const unsigned track_number) const
      {
        assert(track_number < m_total_number_of_tracks);

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
