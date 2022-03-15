/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cassert>
#include "BackendCommon.h"
#include "Common.h"

namespace Allen {
  /**
   * @brief Identifiable Type IDs.
   * @details CUDA does not support RTTI: typeid, dynamic_cast or std::type_info.
   *          TypeIDs provides a list of identifiable type ids for Allen datatypes.
   */
  enum class TypeIDs {
    VeloTracks,
    UTTracks,
    SciFiTracks,
    VeloUTTracks,
    LongTracks,
    BasicParticle,
    CompositeParticle,
    BasicParticles,
    CompositeParticles
  };

  /**
   * @brief Interface for any multi event container.
   * @details Each multi event container should be identifiable with a type ID,
   *          which should be implemented in the inheriting class.
   *          IMultiEventContainer acts as a generic type that can hold various
   *          kinds of containers.
   */
  struct IMultiEventContainer {
    virtual __host__ __device__ Allen::TypeIDs contained_type_id() const = 0;
    virtual __host__ __device__ ~IMultiEventContainer() {}
  };

  /**
   * @brief A multi event container of type T.
   * @details MultiEventContainers is a read-only datatype that holds
   *          the information of several events for type T.
   *          The contents of the container can be accessed through
   *          number_of_events() and container(). The contained type id
   *          is also accessible, and provides a specialization
   *          of IMultiEventContainer's contained_type_id().
   */
  template<typename T>
  struct MultiEventContainer : IMultiEventContainer {
  private:
    const T* m_container = nullptr;
    unsigned m_number_of_events = 0;

  public:
    using contained_type = T;
    MultiEventContainer() = default;
    __host__ __device__ MultiEventContainer(const T* container, const unsigned number_of_events) :
      m_container(container), m_number_of_events(number_of_events)
    {}
    __host__ __device__ unsigned number_of_events() const { return m_number_of_events; }
    __host__ __device__ const T& container(const unsigned event_number) const
    {
      assert(m_container != nullptr);
      assert(event_number < m_number_of_events);
      return m_container[event_number];
    }
    __host__ __device__ Allen::TypeIDs contained_type_id() const override { return T::TypeID; }
  };

  /**
   * @brief Allen host / device dynamic cast.
   * @details This dynamic cast implementation works for both
   *          host and device. It allows to identify and cast
   *          IMultiEventContainer* into a requested MultiEventContainer*.
   */
  template<typename T>
  __host__ __device__ auto dyn_cast(IMultiEventContainer* t) {
    using base_t = std::decay_t<std::remove_pointer_t<T>>;
    static_assert(std::is_base_of_v<base_t, IMultiEventContainer>);
    if (t->contained_type_id() == base_t::contained_type::TypeID) {
      return static_cast<T>(t);
    } else {
      return nullptr;
    }
  }

  /**
   * @brief Interface of LHCbID sequence (CRTP).
   * @details An LHCb ID sequence should provide an implementation
   *          to access its number of ids and each individual id.
   */
  template<typename T>
  struct ILHCbIDSequence {
    __host__ __device__ unsigned number_of_ids() const {
      return static_cast<const T*>(this)->number_of_ids_impl();
    }
    __host__ __device__ unsigned id(const unsigned i) const {
      return static_cast<const T*>(this)->id_impl(i);
    }
  };

  /**
   * @brief Interface of LHCb ID container (CRTP).
   * @details An LHCb ID container should implement a method
   *          to provide the number of id sequences it contains,
   *          and each individual id sequence.
   */
  template<typename T>
  struct ILHCbIDContainer {
    __host__ __device__ unsigned number_of_id_sequences() const {
      return static_cast<const T*>(this)->number_of_id_sequences_impl();
    }
    __host__ __device__ const auto& id_sequence(const unsigned i) const {
      return static_cast<const T*>(this)->id_sequence_impl(i);
    }
  };
} // namespace Allen

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
