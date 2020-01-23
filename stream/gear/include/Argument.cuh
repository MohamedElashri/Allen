#pragma once

#include <tuple>

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

// A property datatype data holder.
template<typename T>
struct property_datatype {
  using t = T;

  __host__ __device__ property_datatype(const T& value) : m_value(value) {}
  __host__ __device__ property_datatype() {}
  __host__ __device__ operator T() const { return this->m_value; }
  __host__ __device__ T get() const { return this->m_value; }

protected:
  T m_value;
};

struct DeviceDimensions : property_datatype<std::array<uint, 3>> {
  using property_datatype<std::array<uint, 3>>::property_datatype;

  uint operator[](const uint index) const { return property_datatype<std::array<uint, 3>>::m_value[index]; }

  uint& operator[](const uint index) { return property_datatype<std::array<uint, 3>>::m_value[index]; }

  size_t size() { return property_datatype<std::array<uint, 3>>::m_value.size(); }
};

struct PropertyBlockDimensions : public DeviceDimensions {
  constexpr static auto name {"block_dim"};
  constexpr static std::array<uint, 3> default_value {{32, 1, 1}};
  constexpr static auto description {"block dimensions"};
  using DeviceDimensions::DeviceDimensions;
};

struct PropertyGridDimensions : public DeviceDimensions {
  constexpr static auto name {"grid_dim"};
  constexpr static std::array<uint, 3> default_value {{1, 1, 1}};
  constexpr static auto description {"grid dimensions"};
  using DeviceDimensions::DeviceDimensions;
};

#define PROPERTY(ARGUMENT_NAME, ARGUMENT_TYPE, NAME, DEFAULT_VALUE, DESCRIPTION) \
  struct ARGUMENT_NAME : property_datatype<ARGUMENT_TYPE> {                      \
    constexpr static auto name {NAME};                                           \
    constexpr static auto default_value {DEFAULT_VALUE};                         \
    constexpr static auto description {DESCRIPTION};                             \
    using property_datatype<ARGUMENT_TYPE>::property_datatype;                   \
  }

/**
 * @brief Defines dependencies for an algorithm.
 *
 * @tparam T The algorithm type.
 * @tparam Args The dependencies.
 */
template<typename T, typename ArgumentsTuple>
struct AlgorithmDependencies {
  using Algorithm = T;
  using Arguments = ArgumentsTuple;
};

/**
 * @brief Dependencies for an algorithm, after
 *        being processed by the scheduler machinery.
 */
template<typename T, typename ArgumentsTuple>
struct ScheduledDependencies {
  using Algorithm = T;
  using Arguments = ArgumentsTuple;
};
