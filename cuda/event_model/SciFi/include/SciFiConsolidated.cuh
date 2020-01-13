#pragma once

#include "ConsolidatedTypes.cuh"
#include "SciFiEventModel.cuh"
#include <stdint.h>

namespace SciFi {
  namespace Consolidated {
    template<typename T>
    struct Hits_t : public SciFi::Hits_t<T> {
      __host__ __device__
      Hits_t(typename ForwardType<T, char>::t* base_pointer, const uint track_offset, const uint total_number_of_hits) :
        SciFi::Hits_t<T>(base_pointer, total_number_of_hits, track_offset)
      {}
    };

    typedef const Hits_t<const char> ConstHits;
    typedef Hits_t<char> Hits;

    //---------------------------------------------------------
    // Struct for holding consolidated SciFi track information.
    //---------------------------------------------------------
    template<typename T>
    struct Tracks_t : public ::Consolidated::Tracks {
    private:
      // Indices of associated UT tracks
      typename ForwardType<T, uint>::t* m_ut_track;
      typename ForwardType<T, float>::t* m_qop;
      typename ForwardType<T, MiniState>::t* m_states;

    public:
      __host__ __device__ Tracks_t(
        const uint* atomics_base_pointer,
        const uint* track_hit_number_base_pointer,
        typename ForwardType<T, float>::t* qop_base_pointer,
        typename ForwardType<T, MiniState>::t* states_base_pointer,
        typename ForwardType<T, uint>::t* ut_track_base_pointer,
        const uint current_event_number,
        const uint number_of_events) :
        ::Consolidated::Tracks(
          atomics_base_pointer,
          track_hit_number_base_pointer,
          current_event_number,
          number_of_events),
        m_ut_track(ut_track_base_pointer + tracks_offset(current_event_number)),
        m_qop(qop_base_pointer + tracks_offset(current_event_number)),
        m_states(states_base_pointer + tracks_offset(current_event_number))
      {}

      __host__ __device__ uint ut_track(const uint index) const { return m_ut_track[index]; }

      __host__ __device__ uint& ut_track(const uint index) { return m_ut_track[index]; }

      __host__ __device__ float qop(const uint index) const { return m_qop[index]; }

      __host__ __device__ float& qop(const uint index) { return m_qop[index]; }

      __host__ __device__ MiniState states(const uint index) const { return m_states[index]; }

      __host__ __device__ MiniState& states(const uint index) { return m_states[index]; }

      __host__ __device__ Hits_t<T> get_hits(T* hits_base_pointer, const uint track_number) const
      {
        return Hits_t<T> {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }
    }; // namespace Consolidated

    typedef const Tracks_t<const char> ConstTracks;
    typedef Tracks_t<char> Tracks;
  } // namespace Consolidated
} // end namespace SciFi
