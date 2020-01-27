#pragma once

#include "ConsolidatedTypes.cuh"
#include "SciFiEventModel.cuh"
#include <stdint.h>

namespace SciFi {
  namespace Consolidated {
    template<typename T>
    struct Hits_t : public SciFi::Hits_t<T> {
      __host__ __device__ Hits_t(T* base_pointer, const uint track_offset, const uint total_number_of_hits) :
        SciFi::Hits_t<T>(base_pointer, total_number_of_hits, track_offset)
      {}
    };

    typedef const Hits_t<const char> ConstHits;
    typedef Hits_t<char> Hits;

    template<typename T>
    struct ExtendedHits_t : public SciFi::ExtendedHits_t<T> {
      __host__ __device__ ExtendedHits_t(
        T* base_pointer,
        const uint track_offset,
        const uint total_number_of_hits,
        const float* inv_clus_res,
        const SciFiGeometry* geom) :
        SciFi::ExtendedHits_t<T>(base_pointer, total_number_of_hits, inv_clus_res, geom, track_offset)
      {}
    };

    typedef const ExtendedHits_t<const char> ConstExtendedHits;
    typedef ExtendedHits_t<char> ExtendedHits;

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

      __host__ __device__ Hits get_hits(char* hits_base_pointer, const uint track_number) const
      {
        return Hits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }

      __host__ __device__ ConstHits get_hits(const char* hits_base_pointer, const uint track_number) const
      {
        return ConstHits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }

      __host__ __device__ ExtendedHits get_hits(
        char* hits_base_pointer,
        const uint track_number,
        const SciFiGeometry* geom,
        const float* inv_clus_res) const
      {
        return ExtendedHits {
          hits_base_pointer, track_offset(track_number), m_total_number_of_hits, inv_clus_res, geom};
      }

      __host__ __device__ ConstExtendedHits get_hits(
        const char* hits_base_pointer,
        const uint track_number,
        const SciFiGeometry* geom,
        const float* inv_clus_res) const
      {
        return ConstExtendedHits {
          hits_base_pointer, track_offset(track_number), m_total_number_of_hits, inv_clus_res, geom};
      }

      __host__ std::vector<uint32_t> get_lhcbids_for_track(
        char* hits_base_pointer,
        const uint track_number) const
      {
        uint32_t* channel = reinterpret_cast<uint32_t*>(hits_base_pointer + sizeof(float) * 3 * total_number_of_hits());
        channel += track_offset(track_number);
        const uint n_hits = number_of_hits(track_number);
        std::vector<uint32_t> lhcbids;
        lhcbids.reserve(n_hits);
        for (uint i_hit = 0; i_hit < n_hits; i_hit++) {
          lhcbids.push_back((10u << 28) + channel[i_hit]);
        }
        return lhcbids;
      }
    }; // namespace Consolidated

    typedef const Tracks_t<const char> ConstTracks;
    typedef Tracks_t<char> Tracks;
  } // namespace Consolidated
} // end namespace SciFi
