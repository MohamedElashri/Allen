#pragma once

#include <cassert>
#include "CudaCommon.h"
#include "Common.h"

namespace Consolidated {

  // base_pointer contains first: an array with the number of tracks in every event
  // second: an array with offsets to the tracks for every event
  struct TracksDescription {
    // Prefix sum of all Velo track sizes
    const uint* m_event_tracks_offsets;
    const uint m_total_number_of_tracks;

#ifdef DEBUG
    // The datatype m_number_of_events is only used in asserts, which are
    // only available in DEBUG mode
    const uint m_number_of_events;

    __device__ __host__ TracksDescription(
      const uint* event_tracks_offsets,
      const uint number_of_events) :
      m_event_tracks_offsets(event_tracks_offsets),
      m_number_of_events(number_of_events),
      m_total_number_of_tracks(event_tracks_offsets[number_of_events]) {}
#else
    __device__ __host__ TracksDescription(
      const uint* event_tracks_offsets,
      const uint number_of_events) :
      m_event_tracks_offsets(event_tracks_offsets),
      m_total_number_of_tracks(event_tracks_offsets[number_of_events]) {}
#endif

    __device__ __host__ uint tracks_offset(const uint event_number) const
    {
      assert(event_number <= m_number_of_events);
      return m_event_tracks_offsets[event_number];
    }

    __device__ __host__ uint number_of_tracks(const uint event_number) const
    {
      assert(event_number < m_number_of_events);
      return m_event_tracks_offsets[event_number + 1] - m_event_tracks_offsets[event_number];
    }

    __device__ __host__ uint total_number_of_tracks() const {
      return m_total_number_of_tracks;
    }
  };

  // atomics_base_pointer size needed: 2 * number_of_events
  struct Tracks : public TracksDescription {
    const uint* m_offsets_track_number_of_hits;
    const uint m_total_number_of_hits;

    __device__ __host__ Tracks(
      const uint* event_tracks_offsets,
      const uint* track_hit_number_base_pointer,
      const uint current_event_number,
      const uint number_of_events) :
      TracksDescription(event_tracks_offsets, number_of_events),
      m_offsets_track_number_of_hits(track_hit_number_base_pointer + event_tracks_offsets[current_event_number]),
      m_total_number_of_hits(*(track_hit_number_base_pointer + event_tracks_offsets[number_of_events])) {}

    __device__ __host__ uint track_offset(const uint track_number) const
    {
      assert(track_number <= m_total_number_of_tracks);
      return m_offsets_track_number_of_hits[track_number];
    }

    __device__ __host__ uint number_of_hits(const uint track_number) const
    {
      assert(track_number < m_total_number_of_tracks);
      return m_offsets_track_number_of_hits[track_number + 1] - m_offsets_track_number_of_hits[track_number];
    }

    __device__ __host__ uint total_number_of_hits () const {
      return m_total_number_of_hits;
    }
  };

} // namespace Consolidated
