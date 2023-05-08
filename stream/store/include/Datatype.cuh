/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
    __host__ __device__ input_datatype() {}
    __host__ __device__ input_datatype(Allen::device::span<type> value) : datatype<type>(value) {}
    __host__ __device__ type operator[](const unsigned index) const { return this->get()[index]; }
  };

  // Output datatypes return pointers that can be modified.
  template<typename T>
  struct output_datatype : datatype<T> {
    using type = T;
    __host__ __device__ output_datatype() {}
    __host__ __device__ output_datatype(Allen::device::span<type> value) : datatype<type>(value) {}
    __host__ __device__ type& operator[](const unsigned index) { return this->get()[index]; }
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

  /**
   * @brief A property datatype data holder.
   */
  template<typename T, typename = void>
  struct property_datatype {
  };

// Note: The following code avoid red herring:
//       missing return statement at end of non-void function
#ifdef __CUDACC__
#pragma push
#if __CUDACC_VER_MAJOR__ > 11 || (__CUDACC_VER_MAJOR__ == 11 && __CUDACC_VER_MINOR__ >= 6)
#pragma nv_diag_suppress = 940
#else
#pragma diag_suppress = 940
#endif
#endif

  /**
   * @brief Trivially copyable datatype holders can be accessed on either host or device.
   * @details Those types that support conversions to dim3 and std::array<unsigned, 3> can also
   *          invoke the operator dim3(), which can be used as the kernel calling parameters.
   */
  template<typename T>
  struct property_datatype<T, std::enable_if_t<std::is_trivially_copyable_v<T>>> {
    using t = T;

    constexpr property_datatype() = default;
    constexpr property_datatype(const t& value) : m_value(value) {}
    __host__ __device__ operator t() const { return this->m_value; }
    __host__ __device__ t get() const { return this->m_value; }
    __host__ __device__ operator dim3() const
    {
      static_assert(
        (std::is_convertible_v<T, dim3> ||
         std::is_same_v<std::decay_t<T>, std::array<unsigned, 3>>) &&"The dim3 operator can only be invoked on "
                                                                     "convertible types or std::array<unsigned, 3>");
      if constexpr (std::is_convertible_v<T, dim3>) {
        return m_value;
      }
      else if constexpr (std::is_same_v<std::decay_t<T>, std::array<unsigned, 3>>) {
        return {m_value[0], m_value[1], m_value[2]};
      }
    }

  protected:
    t m_value;
  };

#ifdef __CUDACC__
#pragma pop
#endif

  /**
   * @brief Non-trivially copyable datatype holders can be accessed solely on the host.
   */
  template<typename T>
  struct property_datatype<T, std::enable_if_t<!std::is_trivially_copyable_v<T>>> {
    using t = T;

    property_datatype() = default;
    property_datatype(const t& value) : m_value(value) {}
    __host__ operator t() const { return this->m_value; }
    __host__ t get() const { return this->m_value; }

  protected:
    t m_value;
  };

// Properties have an additional property method to be able to parse it with libclang.
// libclang relies on name and description being 2nd and 3rd arguments of this macro function.
#define PROPERTY(ARGUMENT_NAME, NAME, DESCRIPTION, ...)                    \
  struct ARGUMENT_NAME : Allen::Store::property_datatype<__VA_ARGS__> {    \
    constexpr static auto name {NAME};                                     \
    constexpr static auto description {DESCRIPTION};                       \
    using Allen::Store::property_datatype<__VA_ARGS__>::property_datatype; \
    void property(__VA_ARGS__) {}                                          \
  }

} // namespace Allen::Store
