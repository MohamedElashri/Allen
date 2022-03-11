/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cassert>
#include "BackendCommon.h"
#include "Common.h"

// TODO: Really need to get rid of this.
#include "PV_Definitions.cuh"

// Let's use CRTP:

// // Interface
// template <typename T>
// struct interface {
//     __device__ void velo_track(int arg) const {
//         static_cast<const T*>(this)->velo_track_impl(arg);
//     }
// };
// // Implementation
// struct derived : interface<derived> {
//     friend class interface;
//     private:
//     __device__ void velo_track_impl(int arg) const {
//         printf("%i\n", arg);
//     }
// };
// template<typename T>
// __device__ void bar(const T& i) {
//     i.velo_track(3);
// }
// __global__ void foo () {
//     derived a;
//     bar(a);
// }

// Some ideas (brainstorming)
// 1. Interfaces:
// - LHCbIDSequence, LHCbIDContainer
// - Velo track, UT track, scifi track
// 2. Function that returns a generic view
// - velo_track (interface) that returns a velo track view.
// 3. Track containers are stored in "segments"

// struct IVeloTrackContainer {
//   static bool is_velo_track_container(const IMultiEventContainer& mec) {
//     return mec.type_id() == VeloTracks || mec.type_id() == VeloSciFiTracks;
//   }
//   virtual Allen::Views::Velo::Consolidated::Track velo_track() const = 0;
// };

// template<typename T>
// __device__ foo(T& t) {
//   t.velo_track();
// }

namespace Allen {
  // TypeID functionality - Allows dynamic_casting on the device
  enum class TypeIDs {
    VeloTracks,
    UTTracks,
    SciFiTracks,
    VeloUTTracks,
    VeloSciFiTracks,
    VeloUTSciFiTracks
  };

  template<typename T>
  __host__ __device__ Allen::TypeIDs identify()
  {
    return T::TypeID;
  }

  struct IMultiEventContainer {
    virtual __host__ __device__ Allen::TypeIDs type_id() const = 0;
    virtual __host__ __device__ ~IMultiEventContainer() {}
  };

  template<typename T>
  struct MultiEventContainer : IMultiEventContainer {
  private:
    const T* m_container = nullptr;
    unsigned m_number_of_events = 0;

  public:
    MultiEventContainer() = default;
    __host__ __device__ MultiEventContainer(const T* container, const unsigned number_of_events) :
      m_container(container), m_number_of_events(number_of_events)
    {}
    __host__ __device__ unsigned number_of_events() const { return m_number_of_events; }
    __host__ __device__ const T& container(const unsigned event_number) const
    {
      assert(event_number < m_number_of_events);
      return m_container[event_number];
    }
    __host__ __device__ Allen::TypeIDs type_id() const override { return Allen::identify<T>(); }
  };

  // ID interfaces (using CRTP)
  template<typename T>
  struct ILHCbIDSequence {
    __host__ __device__ unsigned number_of_ids() const {
      return static_cast<const T*>(this)->number_of_ids_impl();
    }
    __host__ __device__ unsigned id(const unsigned i) const {
      return static_cast<const T*>(this)->id_impl(i);
    }
  };

  template<typename T>
  struct ILHCbIDContainer {
    __host__ __device__ unsigned number_of_id_sequences() const {
      return static_cast<const T*>(this)->number_of_id_sequences_impl();
    }
    __host__ __device__ const auto& id_sequence(const unsigned i) const {
      return static_cast<const T*>(this)->id_sequence_impl(i);
    }
  };

  template<typename T>
  struct IMultiEventLHCbIDContainer {
    __host__ __device__ unsigned number_of_id_containers() const {
      return static_cast<const T*>(this)->number_of_id_containers_impl();
    }
    __host__ __device__ const auto& id_container(const unsigned) const {
      return static_cast<const T*>(this)->id_container_impl();
    }
  };

  // track;
  // track? track->velo_segment(); track->ut_segment(); track->scifi_segment();

  template<typename T>
  struct IVeloTrack {
    __host__ __device__ Allen::Views::Velo::Consolidated::Segment velo_segment() const {
      return static_cast<const T*>(this)->velo_segment_impl();
    }
  };

  template<typename T>
  struct IUTTrack {
    __host__ __device__ Allen::Views::UT::Consolidated::Segment ut_segment() const {
      return static_cast<const T*>(this)->ut_segment_impl();
    }
  };

  template<typename T>
  struct ISciFiTrack {
    __host__ __device__ Allen::Views::Velo::Consolidated::Segment scifi_segment() const {
      return static_cast<const T*>(this)->scifi_segment_impl();
    }
  };
} // namespace Allen

template<typename T>
void ut_bar(const T& mec) {
  // Do stuff
}

template<typename T>
void velo_bar(const T& mec) {
  // Do stuff
}

void foo(const IMultiEventContainer* mec) {
  if (mec->type_id() == VeloTracks) {
    velo_bar()
  }
  
}

namespace Consolidated {

  // base_pointer contains first: an array with the number of tracks in every event
  // second: an array with offsets to the tracks for every event
  struct TracksDescription {
    // Prefix sum of all Velo track sizes
    const unsigned* m_event_tracks_offsets;
    const unsigned m_total_number_of_tracks;

#ifdef ALLEN_DEBUG
    // The datatype m_number_of_events is only used in asserts, which are
    // only available in DEBUG mode
    const unsigned m_number_of_events;

    __device__ __host__ TracksDescription(const unsigned* event_tracks_offsets, const unsigned number_of_events) :
      m_event_tracks_offsets(event_tracks_offsets), m_total_number_of_tracks(event_tracks_offsets[number_of_events]),
      m_number_of_events(number_of_events)
    {}
#else
    __device__ __host__ TracksDescription(const unsigned* event_tracks_offsets, const unsigned number_of_events) :
      m_event_tracks_offsets(event_tracks_offsets), m_total_number_of_tracks(event_tracks_offsets[number_of_events])
    {}
#endif

    __device__ __host__ unsigned tracks_offset(const unsigned event_number) const
    {
#ifdef ALLEN_DEBUG
      assert(event_number <= m_number_of_events);
#endif
      return m_event_tracks_offsets[event_number];
    }

    __device__ __host__ unsigned number_of_tracks(const unsigned event_number) const
    {
#ifdef ALLEN_DEBUG
      assert(event_number < m_number_of_events);
#endif
      return m_event_tracks_offsets[event_number + 1] - m_event_tracks_offsets[event_number];
    }

    __device__ __host__ unsigned total_number_of_tracks() const { return m_total_number_of_tracks; }
  };

  // atomics_base_pointer size needed: 2 * number_of_events
  struct Tracks : public TracksDescription {
    const unsigned* m_offsets_track_number_of_hits;
    const unsigned m_total_number_of_hits;

    __device__ __host__ Tracks(
      const unsigned* event_tracks_offsets,
      const unsigned* track_hit_number_base_pointer,
      const unsigned current_event_number,
      const unsigned number_of_events) :
      TracksDescription(event_tracks_offsets, number_of_events),
      m_offsets_track_number_of_hits(track_hit_number_base_pointer + event_tracks_offsets[current_event_number]),
      m_total_number_of_hits(*(track_hit_number_base_pointer + event_tracks_offsets[number_of_events]))
    {}

    __device__ __host__ unsigned track_offset(const unsigned track_number) const
    {
      assert(track_number <= m_total_number_of_tracks);
      return m_offsets_track_number_of_hits[track_number];
    }

    __device__ __host__ unsigned number_of_hits(const unsigned track_number) const
    {
      assert(track_number < m_total_number_of_tracks);
      return m_offsets_track_number_of_hits[track_number + 1] - m_offsets_track_number_of_hits[track_number];
    }

    __device__ __host__ unsigned total_number_of_hits() const { return m_total_number_of_hits; }
  };

} // namespace Consolidated
