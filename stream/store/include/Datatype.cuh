/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <array>
#include <string>
#include <BackendCommon.h>

// Support for masks
// Masks are unsigned inputs / outputs, which the parser and multi ev scheduler
// deal with in a special way. A maximum of one input mask and one output mask per algorithm
// is allowed.
struct mask_t {
  unsigned m_data = 0;

  __host__ __device__ operator unsigned() const { return m_data; }
};

namespace Allen::Store {

  // Struct to hold the types of the dependencies (libClang)
  namespace {
    template<typename... T>
    struct dependencies {
    };
  } // namespace

  // Datatypes can be host, device or aggregates.
  // Note: These structs need to be not templated (libClang).
  struct host_datatype {
  };
  struct device_datatype {
  };
  struct aggregate_datatype {
  };
  struct optional_datatype {
  };

  // A generic datatype data holder.
  template<typename internal_t>
  struct datatype {
    using type = internal_t;
    static_assert(
      Allen::is_trivially_copyable_v<std::remove_const_t<type>> && "Allen datatypes must be trivially copyable");
    constexpr __host__ __device__ datatype(Allen::device::span<type> value) : m_value(value) {}
    constexpr __host__ __device__ datatype() {}
    constexpr __host__ __device__ auto get() const { return m_value; }
    constexpr __host__ __device__ auto data() const { return m_value.data(); }
    constexpr __host__ __device__ auto operator-> () const { return data(); }
    constexpr __host__ __device__ operator type*() const { return data(); }
    constexpr __host__ __device__ auto empty() const { return m_value.empty(); }
    constexpr __host__ __device__ auto size() const { return m_value.size(); }
    constexpr __host__ __device__ auto size_bytes() const { return m_value.size_bytes(); }
    constexpr __host__ __device__ auto subspan(const std::size_t offset) const { return m_value.subspan(offset); }
    constexpr __host__ __device__ auto subspan(const std::size_t offset, const std::size_t count) const
    {
      return m_value.subspan(offset, count);
    }

  protected:
    Allen::device::span<type> m_value;
  };

  // Input datatypes have read-only accessors.
  template<typename T>
  struct input_datatype : datatype<const T> {
    using type = const T;
    constexpr __host__ __device__ input_datatype() {}
    constexpr __host__ __device__ input_datatype(Allen::device::span<type> value) : datatype<type>(value) {}
    constexpr __host__ __device__ type operator[](const unsigned index) const { return this->get()[index]; }
  };

  // Output datatypes return pointers that can be modified.
  template<typename T>
  struct output_datatype : datatype<T> {
    using type = T;
    constexpr __host__ __device__ output_datatype() {}
    constexpr __host__ __device__ output_datatype(Allen::device::span<type> value) : datatype<type>(value) {}
    constexpr __host__ __device__ type& operator[](const unsigned index) { return this->get()[index]; }
  };

// Inputs / outputs have an additional parsable method required for libclang parsing.
#define DEVICE_INPUT(ARGUMENT_NAME, ...)                                                            \
  struct ARGUMENT_NAME : Allen::Store::device_datatype, Allen::Store::input_datatype<__VA_ARGS__> { \
    using Allen::Store::input_datatype<__VA_ARGS__>::input_datatype;                                \
    void parameter(__VA_ARGS__) const;                                                              \
  }

#define HOST_INPUT(ARGUMENT_NAME, ...)                                                            \
  struct ARGUMENT_NAME : Allen::Store::host_datatype, Allen::Store::input_datatype<__VA_ARGS__> { \
    using Allen::Store::input_datatype<__VA_ARGS__>::input_datatype;                              \
    void parameter(__VA_ARGS__) const;                                                            \
  }

#define DEVICE_OUTPUT(ARGUMENT_NAME, ...)                                                            \
  struct ARGUMENT_NAME : Allen::Store::device_datatype, Allen::Store::output_datatype<__VA_ARGS__> { \
    using Allen::Store::output_datatype<__VA_ARGS__>::output_datatype;                               \
    void parameter(__VA_ARGS__);                                                                     \
  }

#define HOST_OUTPUT(ARGUMENT_NAME, ...)                                                            \
  struct ARGUMENT_NAME : Allen::Store::host_datatype, Allen::Store::output_datatype<__VA_ARGS__> { \
    using Allen::Store::output_datatype<__VA_ARGS__>::output_datatype;                             \
    void parameter(__VA_ARGS__);                                                                   \
  }

#define DEVICE_OUTPUT_WITH_DEPENDENCIES(ARGUMENT_NAME, DEPS, ...)                                    \
  struct ARGUMENT_NAME : Allen::Store::device_datatype, Allen::Store::output_datatype<__VA_ARGS__> { \
    using Allen::Store::output_datatype<__VA_ARGS__>::output_datatype;                               \
    DEPS parameter(__VA_ARGS__);                                                                     \
  }

#define HOST_OUTPUT_WITH_DEPENDENCIES(ARGUMENT_NAME, DEPS, ...)                                    \
  struct ARGUMENT_NAME : Allen::Store::host_datatype, Allen::Store::output_datatype<__VA_ARGS__> { \
    using Allen::Store::output_datatype<__VA_ARGS__>::output_datatype;                             \
    DEPS parameter(__VA_ARGS__);                                                                   \
  }

#define MASK_INPUT(ARGUMENT_NAME)                                                              \
  struct ARGUMENT_NAME : Allen::Store::device_datatype, Allen::Store::input_datatype<mask_t> { \
    using Allen::Store::input_datatype<mask_t>::input_datatype;                                \
    void parameter(mask_t) const;                                                              \
  }

#define MASK_OUTPUT(ARGUMENT_NAME)                                                              \
  struct ARGUMENT_NAME : Allen::Store::device_datatype, Allen::Store::output_datatype<mask_t> { \
    using Allen::Store::output_datatype<mask_t>::output_datatype;                               \
    void parameter(mask_t);                                                                     \
  }

// Support for optional input aggregates
#define DEVICE_INPUT_OPTIONAL(ARGUMENT_NAME, ...)                    \
  struct ARGUMENT_NAME : Allen::Store::device_datatype,              \
                         Allen::Store::optional_datatype,            \
                         Allen::Store::input_datatype<__VA_ARGS__> { \
    using Allen::Store::input_datatype<__VA_ARGS__>::input_datatype; \
    void parameter(__VA_ARGS__) const;                               \
  }

#define HOST_INPUT_OPTIONAL(ARGUMENT_NAME, ...)                      \
  struct ARGUMENT_NAME : Allen::Store::host_datatype,                \
                         Allen::Store::optional_datatype,            \
                         Allen::Store::input_datatype<__VA_ARGS__> { \
    using Allen::Store::input_datatype<__VA_ARGS__>::input_datatype; \
    void parameter(__VA_ARGS__) const;                               \
  }

#define DEPENDENCIES(...) Allen::Store::dependencies<__VA_ARGS__>

} // namespace Allen::Store
