/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cassert>
#include "BackendCommon.h"
#include "Common.h"

// Deprecated
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

  // base_pointer contains first: an array with the number of seeds in every event
  // second: an array with offsets to the seeds for every event
  struct SeedsDescription {
    // Prefix sum of all Velo seed sizes
    const unsigned* m_event_seeds_offsets;
    const unsigned m_total_number_of_seeds;

#ifdef ALLEN_DEBUG
    // The datatype m_number_of_events is only used in asserts, which are
    // only available in DEBUG mode
    const unsigned m_number_of_events;

    __device__ __host__ SeedsDescription(const unsigned* event_seeds_offsets, const unsigned number_of_events) :
      m_event_seeds_offsets(event_seeds_offsets), m_total_number_of_seeds(event_seeds_offsets[number_of_events]),
      m_number_of_events(number_of_events)
    {}
#else
    __device__ __host__ SeedsDescription(const unsigned* event_seeds_offsets, const unsigned number_of_events) :
      m_event_seeds_offsets(event_seeds_offsets), m_total_number_of_seeds(event_seeds_offsets[number_of_events])
    {}
#endif

    __device__ __host__ unsigned seeds_offset(const unsigned event_number) const
    {
#ifdef ALLEN_DEBUG
      assert(event_number <= m_number_of_events);
#endif
      return m_event_seeds_offsets[event_number];
    }

    __device__ __host__ unsigned number_of_seeds(const unsigned event_number) const
    {
#ifdef ALLEN_DEBUG
      assert(event_number < m_number_of_events);
#endif
      return m_event_seeds_offsets[event_number + 1] - m_event_seeds_offsets[event_number];
    }

    __device__ __host__ unsigned total_number_of_seeds() const { return m_total_number_of_seeds; }
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

  struct Seeds : public SeedsDescription {
    const unsigned* m_offsets_seed_number_of_hits;
    const unsigned m_total_number_of_hits;

    __device__ __host__ Seeds(
      const unsigned* event_seeds_offsets,
      const unsigned* seed_hit_number_base_pointer,
      const unsigned current_event_number,
      const unsigned number_of_events) :
      SeedsDescription(event_seeds_offsets, number_of_events),
      m_offsets_seed_number_of_hits(seed_hit_number_base_pointer + event_seeds_offsets[current_event_number]),
      m_total_number_of_hits(*(seed_hit_number_base_pointer + event_seeds_offsets[number_of_events]))
    {}

    __device__ __host__ unsigned seed_offset(const unsigned seed_number) const
    {
      // std::cout << "LoH: Asserting seed offset" << std::endl;
      assert(seed_number <= m_total_number_of_seeds);
      // std::cout << "LoH: Asserted seed offset" << std::endl;
      return m_offsets_seed_number_of_hits[seed_number];
    }

    __device__ __host__ unsigned number_of_hits(const unsigned seed_number) const
    {
      // std::cout << "LoH: Asserting number of hits" << std::endl;
      assert(seed_number < m_total_number_of_seeds);
      // std::cout << "LoH: Asserted number of hits" << std::endl;
      return m_offsets_seed_number_of_hits[seed_number + 1] - m_offsets_seed_number_of_hits[seed_number];
    }

    __device__ __host__ unsigned total_number_of_hits() const { return m_total_number_of_hits; }
  };

} // namespace Consolidated
