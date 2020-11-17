/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ConsolidatedTypes.cuh"
#include "UTEventModel.cuh"
#include <stdint.h>

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
        auto plane_code_base_pointer = reinterpret_cast<typename ForwardType<T, uint8_t>::t*>(m_base_pointer + 6 * m_total_number_of_hits);
        return plane_code_base_pointer[m_offset + index];
      }

      __host__ __device__ uint8_t& plane_code(const unsigned index)
      {
        assert(m_offset + index < m_total_number_of_hits);
        auto plane_code_base_pointer = reinterpret_cast<typename ForwardType<T, uint8_t>::t*>(m_base_pointer + 6 * m_total_number_of_hits);
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

      __host__ std::vector<uint32_t> get_lhcbids_for_track(const char* hits_base_pointer, const unsigned track_number) const
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
