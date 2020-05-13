#pragma once

#include <tuple>
#include <boost/hana/define_struct.hpp>
#include <boost/hana/members.hpp>

// Datatypes can be host or device.
// Note: These structs need to be not templated.
struct host_datatype {
};

struct device_datatype {
};

// A generic datatype* data holder.
template<typename internal_t>
struct datatype {
  using type = internal_t;
  __host__ __device__ datatype(type* value) : m_value(value) {}
  __host__ __device__ datatype() {}

protected:
  type* m_value;
};

// Input datatypes have read-only accessors.
template<typename internal_t>
struct input_datatype : datatype<internal_t> {
  using type = typename datatype<internal_t>::type;
  __host__ __device__ input_datatype() {}
  __host__ __device__ input_datatype(type* value) : datatype<internal_t>(value) {}
  __host__ __device__ operator const type*() const { return const_cast<const type*>(this->m_value); }
  __host__ __device__ const type* get() const { return const_cast<const type*>(this->m_value); }
};

// Output datatypes return pointers that can be modified.
template<typename internal_t>
struct output_datatype : datatype<internal_t> {
  using type = typename datatype<internal_t>::type;
  __host__ __device__ output_datatype() {}
  __host__ __device__ output_datatype(type* value) : datatype<internal_t>(value) {}
  __host__ __device__ operator type*() const { return this->m_value; }
  __host__ __device__ type* get() const { return this->m_value; }
};

// Datatypes can be:
// * device / host
// * input / output
template<typename internal_t>
struct input_device_datatype : device_datatype, input_datatype<internal_t> {
  using type = typename input_datatype<internal_t>::type;
  __host__ __device__ input_device_datatype() {}
  __host__ __device__ input_device_datatype(type* value) : input_datatype<internal_t>(value) {}
};

template<typename internal_t>
struct output_device_datatype : device_datatype, output_datatype<internal_t> {
  using type = typename output_datatype<internal_t>::type;
  __host__ __device__ output_device_datatype() {}
  __host__ __device__ output_device_datatype(type* value) : output_datatype<internal_t>(value) {}
};

template<typename internal_t>
struct input_host_datatype : host_datatype, input_datatype<internal_t> {
  using type = typename input_datatype<internal_t>::type;
  __host__ __device__ input_host_datatype() {}
  __host__ __device__ input_host_datatype(type* value) : input_datatype<internal_t>(value) {}
};

template<typename internal_t>
struct output_host_datatype : host_datatype, output_datatype<internal_t> {
  using type = typename output_datatype<internal_t>::type;
  __host__ __device__ output_host_datatype() {}
  __host__ __device__ output_host_datatype(type* value) : output_datatype<internal_t>(value) {}
};

#define DEVICE_INPUT(ARGUMENT_NAME, ARGUMENT_TYPE)                     \
  struct ARGUMENT_NAME : input_device_datatype<ARGUMENT_TYPE> {        \
    using input_device_datatype<ARGUMENT_TYPE>::input_device_datatype; \
  }

#define DEVICE_OUTPUT(ARGUMENT_NAME, ARGUMENT_TYPE)                      \
  struct ARGUMENT_NAME : output_device_datatype<ARGUMENT_TYPE> {         \
    using output_device_datatype<ARGUMENT_TYPE>::output_device_datatype; \
  }

#define HOST_INPUT(ARGUMENT_NAME, ARGUMENT_TYPE)                   \
  struct ARGUMENT_NAME : input_host_datatype<ARGUMENT_TYPE> {      \
    using input_host_datatype<ARGUMENT_TYPE>::input_host_datatype; \
  }

#define HOST_OUTPUT(ARGUMENT_NAME, ARGUMENT_TYPE)                    \
  struct ARGUMENT_NAME : output_host_datatype<ARGUMENT_TYPE> {       \
    using output_host_datatype<ARGUMENT_TYPE>::output_host_datatype; \
  }

// Struct that mimics std::array<uint, 3> and works with CUDA.
struct DeviceDimensions {
  uint x;
  uint y;
  uint z;

  constexpr DeviceDimensions() : x(1), y(1), z(1) {}
  constexpr DeviceDimensions(const DeviceDimensions& other) : x(other.x), y(other.y), z(other.z) {}
  constexpr DeviceDimensions(const std::array<uint, 3>& v) : x(v[0]), y(v[1]), z(v[2]) {}
};

// A property datatype data holder.
template<typename T>
struct property_datatype {
  using t = T;

  __host__ __device__ constexpr property_datatype(const t& value) : m_value(value) {}
  __host__ __device__ constexpr property_datatype() {}
  __host__ __device__ operator t() const { return this->m_value; }
  __host__ __device__ t get() const { return this->m_value; }
  __host__ __device__ operator dim3() const;

protected:
  t m_value;
};

template<>
struct property_datatype<DeviceDimensions> {
  using t = DeviceDimensions;

  constexpr property_datatype(const t& value) : m_value(value) {}
  constexpr property_datatype() {}
  operator t() const { return this->m_value; }
  t get() const { return this->m_value; }
  operator dim3() const { return {this->m_value.x, this->m_value.y, this->m_value.z}; }

protected:
  t m_value;
};

#define PROPERTY(ARGUMENT_NAME, ARGUMENT_TYPE, NAME, DESCRIPTION) \
  struct ARGUMENT_NAME : property_datatype<ARGUMENT_TYPE> {       \
    constexpr static auto name {NAME};                            \
    constexpr static auto description {DESCRIPTION};              \
    using property_datatype<ARGUMENT_TYPE>::property_datatype;    \
  }

/**
 * @brief Dependencies for an algorithm, after
 *        being processed by the scheduler machinery.
 */
template<typename T, typename ArgumentsTuple>
struct ScheduledDependencies {
  using Algorithm = T;
  using Arguments = ArgumentsTuple;
};

#define DEFINE_PARAMETERS(CLASS_NAME, ...)             \
  struct CLASS_NAME {                                  \
    BOOST_HANA_DEFINE_STRUCT(CLASS_NAME, __VA_ARGS__); \
  };
