/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cassert>
#include "BackendCommon.h"
#include "Common.h"

// TODO: Really need to get rid of this.
#include "PV_Definitions.cuh"

namespace Allen {
  template<typename T>
  struct MultiEventContainer {
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
  };

  struct ILHCbIDStructure {
    virtual __host__ __device__ unsigned number_of_substructures() const = 0;
    virtual __host__ __device__ ~ILHCbIDStructure() {}
  };

  struct ILHCbIDComposite : ILHCbIDStructure {
  private:
    const ILHCbIDStructure* m_substructures = nullptr;
    unsigned m_number_of_substructures = 0;
    unsigned m_index = 0;
    unsigned m_total_number_of_composites = 0;

  public:
    __host__ __device__ ILHCbIDComposite(
      const ILHCbIDStructure* substructures,
      unsigned number_of_substructures,
      unsigned index,
      unsigned total_number_of_composites) :
      m_substructures(substructures),
      m_number_of_substructures(number_of_substructures),
      m_index(index),
      m_total_number_of_composites(total_number_of_composites)
    {}

    __host__ __device__ unsigned number_of_substructures() const override { 
      return m_number_of_substructures; 
    }

    __host__ __device__ const ILHCbIDStructure& substructure(const unsigned substructure_index) const
    {
      assert(substructure_index < m_number_of_substructures);
      return m_substructures[m_total_number_of_composites * substructure_index + m_index];
    }
  };

  struct ILHCbIDSequence : ILHCbIDStructure {
    __host__ __device__ unsigned number_of_substructures() const override { return 1; }
    virtual __host__ __device__ unsigned number_of_ids() const = 0;
    virtual __host__ __device__ unsigned id(const unsigned) const = 0;
  };

  struct ILHCbIDContainer {
    virtual __host__ __device__ unsigned number_of_id_structures() const = 0;
    virtual __host__ __device__ const ILHCbIDStructure& id_structure(const unsigned) const = 0;
    virtual __host__ __device__ ~ILHCbIDContainer() {}
  };

  struct IMultiEventLHCbIDContainer {
    virtual __host__ __device__ unsigned number_of_id_containers() const = 0;
    virtual __host__ __device__ const ILHCbIDContainer& id_container(const unsigned) const = 0;
    virtual __host__ __device__ ~IMultiEventLHCbIDContainer() {}
  };

  template<typename T>
  struct MultiEventLHCbIDContainer : MultiEventContainer<T>, IMultiEventLHCbIDContainer {
    using MultiEventContainer<T>::MultiEventContainer;
    __host__ __device__ unsigned number_of_id_containers() const override
    {
      return MultiEventContainer<T>::number_of_events();
    }
    __host__ __device__ const ILHCbIDContainer& id_container(const unsigned event_number) const override
    {
      return MultiEventContainer<T>::container(event_number);
    }
  };
} // namespace Allen

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
