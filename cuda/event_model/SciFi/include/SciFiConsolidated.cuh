#pragma once

#include "ConsolidatedTypes.cuh"
#include "SciFiEventModel.cuh"
#include <stdint.h>

namespace SciFi {
  namespace Consolidated {
    template<typename T>
    struct Hits : public SciFi::Hits<T> {
      __host__ __device__ Hits(typename ForwardType<T>::char_t* base_pointer, const uint track_offset, const uint total_number_of_hits) :
        SciFi::Hits<T>(base_pointer, total_number_of_hits, track_offset) {}
    };

    //---------------------------------------------------------
    // Struct for holding consolidated SciFi track information.
    //---------------------------------------------------------
    struct Tracks : public ::Consolidated::Tracks {
    private:
      // Indices of associated UT tracks.
      const uint* m_ut_track;
      const float* m_qop;
      const MiniState* m_states;

    public:
      __host__ __device__ Tracks(
        const uint* atomics_base_pointer,
        const uint* track_hit_number_base_pointer,
        const float* qop_base_pointer,
        const MiniState* states_base_pointer,
        const uint* ut_track_base_pointer,
        const uint current_event_number,
        const uint number_of_events) :
        ::Consolidated::Tracks(
          atomics_base_pointer,
          track_hit_number_base_pointer,
          current_event_number,
          number_of_events),
        m_ut_track(ut_track_base_pointer + tracks_offset(current_event_number)),
        m_qop (qop_base_pointer + tracks_offset(current_event_number)),
        m_states(states_base_pointer + tracks_offset(current_event_number))
      {}

      uint ut_track(const uint index) {
        return m_ut_track[index];
      }

      float qop(const uint index) {
        return m_qop[index];
      }

      MiniState states(const uint index) {
        return m_states[index];
      }

      template<typename T>
      __host__ __device__ Hits<T> get_hits(
        T* hits_base_pointer,
        const uint track_number,
        const SciFiGeometry* scifi_geometry,
        const float* dev_inv_clus_res) const
      {
        return Hits<T> {
          hits_base_pointer, track_offset(track_number), m_total_number_of_hits, scifi_geometry, dev_inv_clus_res};
      }
    }; // namespace Consolidated

  } // namespace Consolidated
} // end namespace SciFi
