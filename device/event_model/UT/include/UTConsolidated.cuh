/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ConsolidatedTypes.cuh"
#include "UTEventModel.cuh"
#include <stdint.h>
#include <cassert>

namespace Allen {
  namespace Views {
    namespace UT {
      namespace Consolidated {

        struct Hit {
          using plane_code_t = uint8_t;

        private:
          const float* m_base_pointer = nullptr;
          unsigned m_index = 0;
          unsigned m_total_number_of_hits = 0;

        public:
          Hit() = default;

          __host__ __device__
          Hit(const float* base_pointer, const unsigned index, const unsigned total_number_of_hits) :
            m_base_pointer(base_pointer),
            m_index(index), m_total_number_of_hits(total_number_of_hits)
          {}

          __host__ __device__ uint8_t plane_code() const
          {
            auto plane_code_base_pointer =
              reinterpret_cast<const uint8_t*>(m_base_pointer + 6 * m_total_number_of_hits);
            return plane_code_base_pointer[m_index];
          }

          __host__ __device__ float yBegin() const { return m_base_pointer[m_index]; }

          __host__ __device__ float yEnd() const { return m_base_pointer[m_total_number_of_hits + m_index]; }

          __host__ __device__ float zAtYEq0() const { return m_base_pointer[2 * m_total_number_of_hits + m_index]; }

          __host__ __device__ float xAtYEq0() const { return m_base_pointer[3 * m_total_number_of_hits + m_index]; }

          __host__ __device__ float weight() const { return m_base_pointer[4 * m_total_number_of_hits + m_index]; }

          __host__ __device__ uint32_t id() const
          {
            return reinterpret_cast<const uint32_t*>(m_base_pointer)[5 * m_total_number_of_hits + m_index];
          }

          __host__ __device__ operator ::UT::Hit() const
          {
            return ::UT::Hit {yBegin(), yEnd(), zAtYEq0(), xAtYEq0(), weight(), id(), plane_code()};
          }
        };

        struct Hits {
        private:
          const float* m_base_pointer = nullptr;
          unsigned m_offset = 0;
          unsigned m_size = 0;
          unsigned m_total_number_of_hits = 0;

        public:
          Hits() = default;

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
          const Allen::Views::Velo::Consolidated::Track* m_velo_track = nullptr;
          const float* m_qop = nullptr;
          unsigned m_track_index = 0;
          unsigned m_offset = 0;
          unsigned m_number_of_hits = 0;

        public:
          __host__ __device__ Track(
            const Hits* hits,
            const Allen::Views::Velo::Consolidated::Track* velo_track,
            const float* qop,
            const unsigned* offset_tracks,
            const unsigned* offset_track_hit_number,
            const unsigned track_index,
            const unsigned event_number) :
            m_hits(hits + event_number),
            m_velo_track(velo_track), m_qop(qop), m_track_index(track_index)
          {
            const auto offset_event = offset_track_hit_number + offset_tracks[event_number];
            m_offset = offset_event[track_index] - offset_event[0];
            m_number_of_hits = offset_event[track_index + 1] - offset_event[track_index];
          }

          __host__ __device__ unsigned track_index() const { return m_track_index; }

          __host__ __device__ Allen::Views::Velo::Consolidated::Track velo_track() const
          {
            return *m_velo_track;
          }

          __host__ __device__ unsigned number_of_ut_hits() const { return m_number_of_hits; }

          __host__ __device__ unsigned number_of_total_hits() const
          {
            return m_number_of_hits + m_velo_track->number_of_hits();
          }

          __host__ __device__ unsigned qop() const { return m_qop[m_offset + m_track_index]; }

          __host__ __device__ Hit hit(const unsigned ut_hit_index) const
          {
            assert(m_hits != nullptr);
            assert(ut_hit_index < m_number_of_hits);
            return m_hits->hit(m_offset + ut_hit_index);
          }

          __host__ __device__ unsigned number_of_ids() const override { return number_of_total_hits(); }

          __host__ __device__ unsigned id(const unsigned index) const override
          {
            auto n_velo_hits = m_velo_track->number_of_hits();
            if (index < n_velo_hits) {
              return m_velo_track->hit(index).id();
            }
            else {
              return hit(index - n_velo_hits).id();
            }
          }
        };

        struct Tracks : Allen::ILHCbIDContainer {
        private:
          const Track* m_track = nullptr;
          unsigned m_offset = 0;
          unsigned m_size = 0;

        public:
          Tracks() = default;

          __host__ __device__ Tracks(const Track* track, const unsigned* offset_tracks, const unsigned event_number) :
            m_track(track + offset_tracks[event_number]), m_offset(offset_tracks[event_number]),
            m_size(offset_tracks[event_number + 1] - offset_tracks[event_number])
          {}

          __host__ __device__ unsigned size() const { return m_size; }

          __host__ __device__ const Track& track(const unsigned index) const
          {
            assert(m_track != nullptr);
            assert(index < m_size);
            return m_track[index];
          }

          __host__ __device__ unsigned offset() const { return m_offset; }

          __host__ __device__ unsigned number_of_id_sequences() const override { return size(); }

          __host__ __device__ const ILHCbIDSequence& id_sequence(const unsigned container_number) const override
          {
            return track(container_number);
          }
        };

        using MultiEventTracks = Allen::MultiEventLHCbIDContainer<Tracks>;
      } // namespace Consolidated
    }   // namespace UT
  }     // namespace Views
} // namespace Allen

namespace UT {
  namespace Consolidated {
    template<typename T>
    struct Hits_t : public UT::Hits_t<T> {
      using plane_code_t = uint8_t;
      constexpr static unsigned element_size = 5 * sizeof(float) + sizeof(unsigned) + sizeof(plane_code_t);

      using UT::Hits_t<T>::m_base_pointer;
      using UT::Hits_t<T>::m_total_number_of_hits;
      using UT::Hits_t<T>::m_offset;

      __host__ __device__ Hits_t(T* base_pointer, const unsigned offset, const unsigned total_number_of_hits) :
        UT::Hits_t<T>(base_pointer, total_number_of_hits, offset)
      {}

      // Const and lvalue accessors
      __host__ __device__ uint8_t plane_code(const unsigned index) const
      {
        assert(m_offset + index < m_total_number_of_hits);
        auto plane_code_base_pointer =
          reinterpret_cast<Allen::forward_type_t<T, plane_code_t>*>(m_base_pointer + 6 * m_total_number_of_hits);
        return plane_code_base_pointer[m_offset + index];
      }

      __host__ __device__ uint8_t& plane_code(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_hits);
        auto plane_code_base_pointer =
          reinterpret_cast<Allen::forward_type_t<T, plane_code_t>*>(m_base_pointer + 6 * m_total_number_of_hits);
        return plane_code_base_pointer[m_offset + index];
      }

      __host__ __device__ void set(const unsigned hit_number, const UT::Hit& hit)
      {
        this->yBegin(hit_number) = hit.yBegin;
        this->yEnd(hit_number) = hit.yEnd;
        this->zAtYEq0(hit_number) = hit.zAtYEq0;
        this->xAtYEq0(hit_number) = hit.xAtYEq0;
        this->weight(hit_number) = hit.weight;
        this->id(hit_number) = hit.LHCbID;
        plane_code(hit_number) = hit.plane_code;
      }

      __host__ __device__ UT::Hit get(const unsigned hit_number) const
      {
        return UT::Hit {this->yBegin(hit_number),
                        this->yEnd(hit_number),
                        this->zAtYEq0(hit_number),
                        this->xAtYEq0(hit_number),
                        this->weight(hit_number),
                        this->id(hit_number),
                        plane_code(hit_number)};
      }
    };

    typedef const Hits_t<const char> ConstHits;
    typedef Hits_t<char> Hits;

    //-------------------------------------------
    // Struct for holding VELO track information.
    //-------------------------------------------
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

      __host__ __device__ Hits get_hits(char* hits_base_pointer, const unsigned track_number) const
      {
        return Hits {hits_base_pointer, track_offset(track_number), m_total_number_of_hits};
      }

      __host__ std::vector<uint32_t> get_lhcbids_for_track(const char* hits_base_pointer, const unsigned track_number)
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

    template<typename T>
    struct ExtendedTracks_t : public Tracks {
    private:
      // Indices of associated VELO tracks.
      typename ForwardType<T, unsigned>::t* m_velo_track;
      // Array of q/p for each track.
      typename ForwardType<T, float>::t* m_qop;

    public:
      __host__ __device__ ExtendedTracks_t(
        const unsigned* atomics_base_pointer,
        const unsigned* track_hit_number_base_pointer,
        typename ForwardType<T, float>::t* qop_base_pointer,
        typename ForwardType<T, unsigned>::t* velo_track_base_pointer,
        const unsigned current_event_number,
        const unsigned number_of_events) :
        Tracks(atomics_base_pointer, track_hit_number_base_pointer, current_event_number, number_of_events),
        m_velo_track(velo_track_base_pointer + tracks_offset(current_event_number)),
        m_qop(qop_base_pointer + tracks_offset(current_event_number))
      {}

      __host__ __device__ unsigned velo_track(const unsigned index) const { return m_velo_track[index]; }

      __host__ __device__ unsigned& velo_track(const unsigned index) { return m_velo_track[index]; }

      __host__ __device__ float qop(const unsigned index) const { return m_qop[index]; }

      __host__ __device__ float& qop(const unsigned index) { return m_qop[index]; }
    };

    typedef const ExtendedTracks_t<const char> ConstExtendedTracks;
    typedef ExtendedTracks_t<char> ExtendedTracks;
  } // end namespace Consolidated
} // end namespace UT
