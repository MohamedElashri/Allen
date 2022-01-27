/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ConsolidatedTypes.cuh"
#include "SciFiEventModel.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include <stdint.h>

namespace Allen {
  namespace Views {
    namespace SciFi {
      namespace Consolidated {

        struct Hit {
        private:
          const float* m_base_pointer = nullptr;
          unsigned m_index = 0;
          unsigned m_total_number_of_hits = 0;

        public:
          __host__ __device__
          Hit(const float* base_pointer, const unsigned index, const unsigned total_number_of_hits) :
            m_base_pointer(base_pointer),
            m_index(index), m_total_number_of_hits(total_number_of_hits)
          {}

          __host__ __device__ float x0() const { return m_base_pointer[m_index]; }

          __host__ __device__ float z0() const { return m_base_pointer[m_total_number_of_hits + m_index]; }

          __host__ __device__ float endPointY() const { return m_base_pointer[2 * m_total_number_of_hits + m_index]; }

          __host__ __device__ unsigned channel() const
          {
            return reinterpret_cast<const unsigned*>(m_base_pointer)[3 * m_total_number_of_hits + m_index];
          }

          __host__ __device__ unsigned assembled_datatype() const
          {
            return reinterpret_cast<const unsigned*>(m_base_pointer)[4 * m_total_number_of_hits + m_index];
          }

          __host__ __device__ unsigned id() const { return (10u << 28) + channel(); }

          __host__ __device__ unsigned mat() const { return assembled_datatype() & 0x7ff; }

          __host__ __device__ unsigned pseudoSize() const { return (assembled_datatype() >> 11) & 0xf; }

          __host__ __device__ unsigned planeCode() const { return (assembled_datatype() >> 15) & 0x1f; }
        };

        struct Hits {
        private:
          const float* m_base_pointer = nullptr;
          unsigned m_offset = 0;
          unsigned m_size = 0;
          unsigned m_total_number_of_hits = 0;

        public:
          __host__ __device__ Hits(
            const char* base_pointer,
            const unsigned* offset_tracks,
            const unsigned* offset_track_hit_number,
            const unsigned event_number,
            const unsigned number_of_events) :
            m_base_pointer(reinterpret_cast<const float*>(base_pointer)),
            m_offset(offset_track_hit_number[offset_tracks[event_number]]),
            m_size(
              offset_track_hit_number[offset_tracks[event_number + 1]] -
              offset_track_hit_number[offset_tracks[event_number]]),
            m_total_number_of_hits(offset_track_hit_number[offset_tracks[number_of_events]])
          {}

          __host__ __device__ unsigned size() const { return m_size; }

          __host__ __device__ Hit hit(const unsigned index) const
          {
            assert(index < m_size);
            return Hit {m_base_pointer, m_offset + index, m_total_number_of_hits};
          }

          __host__ __device__ unsigned offset() const { return m_offset; }
        };

        struct Track : Allen::ILHCbIDSequence {
        private:
          const Hits* m_hits = nullptr;
          const Allen::Views::UT::Consolidated::Track* m_ut_track = nullptr;
          const float* m_qop = nullptr;
          unsigned m_track_index = 0;
          unsigned m_offset = 0;
          unsigned m_number_of_hits = 0;

        public:
          __host__ __device__ Track(
            const Hits* hits,
            const Allen::Views::UT::Consolidated::Track* ut_track,
            const float* qop,
            const unsigned* offset_tracks,
            const unsigned* offset_track_hit_number,
            const unsigned track_index,
            const unsigned event_number) :
            ILHCbIDSequence {1},
            m_hits(hits + event_number), m_ut_track(ut_track), m_qop(qop + offset_tracks[event_number]),
            m_track_index(track_index)
          {
            const auto offset_event = offset_track_hit_number + offset_tracks[event_number];
            m_offset = offset_event[track_index] - offset_event[0];
            m_number_of_hits = offset_event[track_index + 1] - offset_event[track_index];
          }

          __host__ __device__ unsigned track_index() const { return m_track_index; }

          __host__ __device__ const Allen::Views::UT::Consolidated::Track& ut_track() const { return *m_ut_track; }

          __host__ __device__ const Allen::Views::Velo::Consolidated::Track& velo_track() const
          {
            return m_ut_track->velo_track();
          }

          __host__ __device__ unsigned number_of_scifi_hits() const { return m_number_of_hits; }

          __host__ __device__ unsigned number_of_ut_hits() const { return m_ut_track->number_of_ut_hits(); }

          __host__ __device__ unsigned number_of_velo_hits() const { return velo_track().number_of_hits(); }

          __host__ __device__ unsigned number_of_total_hits() const
          {
            return number_of_velo_hits() + number_of_ut_hits() + number_of_scifi_hits();
          }

          __host__ __device__ float qop() const { return m_qop[m_track_index]; }

          __host__ __device__ Hit hit(const unsigned scifi_hit_index) const
          {
            assert(m_hits != nullptr);
            assert(scifi_hit_index < m_number_of_hits);
            return m_hits->hit(m_offset + scifi_hit_index);
          }

          __host__ __device__ unsigned number_of_ids() const override { return number_of_total_hits(); }

          __host__ __device__ unsigned id(const unsigned index) const override
          {
            if (index < number_of_velo_hits()) {
              return velo_track().hit(index).id();
            }
            else if (index < number_of_ut_hits() + number_of_velo_hits()) {
              return m_ut_track->hit(index - number_of_velo_hits()).id();
            }
            else {
              return hit(index - number_of_velo_hits() - number_of_ut_hits()).id();
            }
          }
        };

        struct Tracks : Allen::ILHCbIDContainer {
        private:
          unsigned m_offset = 0;

        public:
          __host__ __device__ Tracks(const Track* track, const unsigned* offset_tracks, const unsigned event_number) :
            ILHCbIDContainer {track + offset_tracks[event_number],
                              offset_tracks[event_number + 1] - offset_tracks[event_number]},
            m_offset(offset_tracks[event_number])
          {}

          __host__ __device__ unsigned size() const { return m_size; }

          __host__ __device__ const Track& track(const unsigned index) const
          {
            assert(index < m_size);
            return static_cast<const Track*>(m_structure)[index];
          }

          __host__ __device__ unsigned offset() const { return m_offset; }
        };

        using MultiEventTracks = Allen::MultiEventLHCbIDContainer<Tracks>;
      } // namespace Consolidated
    }   // namespace SciFi
  }     // namespace Views
} // namespace Allen

namespace SciFi {
  namespace Consolidated {
    template<typename T>
    struct Hits_t : public SciFi::Hits_t<T> {
      __host__ __device__ Hits_t(T* base_pointer, const unsigned track_offset, const unsigned total_number_of_hits) :
        SciFi::Hits_t<T>(base_pointer, total_number_of_hits, track_offset)
      {}
    };

    typedef const Hits_t<const char> ConstHits;
    typedef Hits_t<char> Hits;

    template<typename T>
    struct ExtendedHits_t : public SciFi::ExtendedHits_t<T> {
      __host__ __device__ ExtendedHits_t(
        T* base_pointer,
        const unsigned track_offset,
        const unsigned total_number_of_hits,
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
      typename ForwardType<T, unsigned>::t* m_ut_track;
      typename ForwardType<T, float>::t* m_qop;
      typename ForwardType<T, MiniState>::t* m_states;

    public:
      __host__ __device__ Tracks_t(
        const unsigned* atomics_base_pointer,
        const unsigned* track_hit_number_base_pointer,
        typename ForwardType<T, float>::t* qop_base_pointer,
        typename ForwardType<T, MiniState>::t* states_base_pointer,
        typename ForwardType<T, unsigned>::t* ut_track_base_pointer,
        const unsigned current_event_number,
        const unsigned number_of_events) :
        ::Consolidated::Tracks(
          atomics_base_pointer,
          track_hit_number_base_pointer,
          current_event_number,
          number_of_events),
        m_ut_track(ut_track_base_pointer + tracks_offset(current_event_number)),
        m_qop(qop_base_pointer + tracks_offset(current_event_number)),
        m_states(states_base_pointer + tracks_offset(current_event_number))
      {}

      __host__ __device__ unsigned ut_track(const unsigned index) const { return m_ut_track[index]; }

      __host__ __device__ unsigned& ut_track(const unsigned index) { return m_ut_track[index]; }

      __host__ __device__ float qop(const unsigned index) const { return m_qop[index]; }

      __host__ __device__ float& qop(const unsigned index) { return m_qop[index]; }

      __host__ __device__ MiniState states(const unsigned index) const { return m_states[index]; }

      __host__ __device__ MiniState& states(const unsigned index) { return m_states[index]; }

      __host__ __device__ Hits get_hits(char* hits_base_pointer, const unsigned track_number) const
      {
        return Hits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }

      __host__ __device__ ConstHits get_hits(const char* hits_base_pointer, const unsigned track_number) const
      {
        return ConstHits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }

      __host__ __device__ ExtendedHits get_hits(
        char* hits_base_pointer,
        const unsigned track_number,
        const SciFiGeometry* geom,
        const float* inv_clus_res) const
      {
        return ExtendedHits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits, inv_clus_res, geom};
      }

      __host__ __device__ ConstExtendedHits get_hits(
        const char* hits_base_pointer,
        const unsigned track_number,
        const SciFiGeometry* geom,
        const float* inv_clus_res) const
      {
        return ConstExtendedHits {
          hits_base_pointer, track_offset(track_number), m_total_number_of_hits, inv_clus_res, geom};
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
    }; // namespace Consolidated

    typedef const Tracks_t<const char> ConstTracks;
    typedef Tracks_t<char> Tracks;
  } // namespace Consolidated
} // end namespace SciFi
