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
    Invalid,
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
   * @brief Interface for any identifiable object.
   * @details Each identifiable object will have with a type ID,
   *          which should be initialized in the inheriting class.
   *          Propertly identifiable classes must extend Identifiable,
   *          provide the TypeID at initialization, and by convention have
   *          a publicly available TypeID. Eg.
   *
   *          struct SomeIdentifiableClass : Identifiable {
   *            constexpr static auto TypeID = Allen::TypeIDs::<some_id>;
   *            SomeIdentifiableClass() : Identifiable(TypeID) {}
   *          };
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
   * @brief Allen host / device dynamic cast.
   * @details This dynamic cast implementation works for both
   *          host and device. It allows to identify and cast
   *          objects inheriting from Identifiable.
   */
  template<typename T, typename U>
  __host__ __device__ T dyn_cast(U* t)
  {
    using derived_t = std::decay_t<std::remove_pointer_t<T>>;
    using base_t = std::decay_t<U>;

    static_assert(std::is_base_of_v<base_t, derived_t> && "dyn casting compatible types");
    static_assert(
      std::is_same_v<TypeIDs, std::decay_t<decltype(derived_t::TypeID)>> && "derived type has a valid TypeID");

    if (t == nullptr) {
      return nullptr;
    }
    else if (t->type_id() == derived_t::TypeID) {
      return static_cast<T>(t);
    }
    return nullptr;
  }
} // namespace Allen