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
   * @brief Allen host / device dynamic cast.
   * @details This dynamic cast implementation works for both
   *          host and device. It allows to identify and cast
   *          IMultiEventContainer* into a requested MultiEventContainer*.
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