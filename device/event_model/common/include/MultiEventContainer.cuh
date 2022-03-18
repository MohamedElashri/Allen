/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "TypeID.cuh"

namespace Allen {
  /**
   * @brief Interface for any identifiable object.
   * @details Each identifiable object will have with a type ID,
   *          which should be initialized in the inheriting class.
   */
  struct Identifiable {
  private:
    TypeIDs m_type_id = TypeIDs::Invalid;

  public:
    Identifiable() = default;
    __host__ __device__ Identifiable(TypeIDs type_id) : m_type_id(type_id) {}
    __host__ __device__ TypeIDs type_id() const { return m_type_id; }
  };

  /**
   * @brief Interface of any multi event container.
   * @details The interface is identifiable, so dyn_cast can be
   *          used to determine the underlying contained object.
   *          Please note that this is not a true interface, in that
   *          it does not provide an interface of what methods a multi
   *          event container implementation should implement. That should
   *          be done via CRTP, but introducing a template would require knowing
   *          the type and restrict the interface usability in the configuration.
   */
  struct IMultiEventContainer : Identifiable {
    using Identifiable::Identifiable;
  };

  /**
   * @brief A multi event container of type T.
   * @details MultiEventContainers is a read-only datatype that holds
   *          the information of several events for type T.
   *          The contents of the container can be accessed through
   *          number_of_events() and container(). The contained TypeID
   *          is also accessible, and the datatype is identifiable.
   */
  template<typename T>
  struct MultiEventContainer : IMultiEventContainer {
  private:
    const T* m_container = nullptr;
    unsigned m_number_of_events = 0;

  public:
    constexpr static auto TypeID = T::TypeID;

    MultiEventContainer() = default;
    __host__ __device__ MultiEventContainer(const T* container, const unsigned number_of_events) :
      IMultiEventContainer(TypeID), m_container(container), m_number_of_events(number_of_events)
    {}
    __host__ __device__ unsigned number_of_events() const { return m_number_of_events; }
    __host__ __device__ const T& container(const unsigned event_number) const
    {
      assert(m_container != nullptr);
      assert(event_number < m_number_of_events);
      return m_container[event_number];
    }
  };

  /**
   * @brief Interface of LHCbID sequence (CRTP).
   * @details An LHCb ID sequence should provide an implementation
   *          to access its number of ids and each individual id.
   */
  template<typename T>
  struct ILHCbIDSequence {
    __host__ __device__ unsigned number_of_ids() const { return static_cast<const T*>(this)->number_of_ids_impl(); }
    __host__ __device__ unsigned id(const unsigned i) const { return static_cast<const T*>(this)->id_impl(i); }
  };

  /**
   * @brief Interface of LHCb ID container (CRTP).
   * @details An LHCb ID container should implement a method
   *          to provide the number of id sequences it contains,
   *          and each individual id sequence.
   */
  template<typename T>
  struct ILHCbIDContainer {
    __host__ __device__ unsigned number_of_id_sequences() const
    {
      return static_cast<const T*>(this)->number_of_id_sequences_impl();
    }
    __host__ __device__ const auto& id_sequence(const unsigned i) const
    {
      return static_cast<const T*>(this)->id_sequence_impl(i);
    }
  };
} // namespace Allen