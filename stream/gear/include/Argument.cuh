#pragma once

#include <tuple>

// Datatypes can be host or device.
// Note: These structs need to be not templated.
struct host_datatype {};

struct device_datatype {};

// A generic datatype data holder.
template<typename internal_t>
struct datatype {
  using type = internal_t;
  datatype(type* value) : m_value(value) {}
  datatype() = default;
  datatype(const datatype&) = default;

protected:
  type* m_value;
};

// Input datatypes have read-only accessors.
template<typename internal_t>
struct in_datatype : datatype<internal_t> {
  using type = typename datatype<internal_t>::type;
  in_datatype() = default;
  in_datatype(type* value) : datatype<internal_t>(value) {}
  operator const type*() const { return const_cast<const type*>(this->m_value); }
  const type* get() const { return const_cast<const type*>(this->m_value); }
};

// Output datatypes return pointers that can be modified.
template<typename internal_t>
struct out_datatype : datatype<internal_t> {
  using type = typename datatype<internal_t>::type;
  out_datatype() = default;
  out_datatype(type* value) : datatype<internal_t>(value) {}
  operator type*() const { return this->m_value; }
  type* get() const { return this->m_value; }
};

// Datatypes can be:
// * device / host
// * input / output
template<typename internal_t>
struct input_datatype : device_datatype, in_datatype<internal_t> {
  using type = typename in_datatype<internal_t>::type;
  input_datatype() = default;
  input_datatype(type* value) : in_datatype<internal_t>(value) {}
};

template<typename internal_t>
struct output_datatype : device_datatype, out_datatype<internal_t> {
  using type = typename out_datatype<internal_t>::type;
  output_datatype() = default;
  output_datatype(type* value) : out_datatype<internal_t>(value) {}
};

template<typename internal_t>
struct input_host_datatype : host_datatype, in_datatype<internal_t> {
  using type = typename in_datatype<internal_t>::type;
  input_host_datatype() = default;
  input_host_datatype(type* value) : in_datatype<internal_t>(value) {}
};

template<typename internal_t>
struct output_host_datatype : host_datatype, out_datatype<internal_t> {
  using type = typename out_datatype<internal_t>::type;
  output_host_datatype() = default;
  output_host_datatype(type* value) : out_datatype<internal_t>(value) {}
};

// Macros in case we go for them
#define DEV_INPUT(ARGUMENT_NAME, ARGUMENT_TYPE) \
  struct ARGUMENT_NAME : input_datatype<ARGUMENT_TYPE> {};

#define DEV_OUTPUT(ARGUMENT_NAME, ARGUMENT_TYPE) \
  struct ARGUMENT_NAME : output_datatype<ARGUMENT_TYPE> {};

#define HOST_INPUT(ARGUMENT_NAME, ARGUMENT_TYPE) \
  struct ARGUMENT_NAME : input_host_datatype<ARGUMENT_TYPE> {};

#define HOST_OUTPUT(ARGUMENT_NAME, ARGUMENT_TYPE) \
  struct ARGUMENT_NAME : output_host_datatype<ARGUMENT_TYPE> {};

// Macro for defining an argument that depends on types.
// This is for the sequence definition.
#define ARG(ARGUMENT_NAME, ...)                  \
  struct ARGUMENT_NAME : __VA_ARGS__ {           \
    constexpr static auto name {#ARGUMENT_NAME}; \
    size_t size;                                 \
    char* offset;                                \
  };

/**
 * @brief Macro for defining arguments in a Handler.
 */
#define ARGUMENTS(...) std::tuple<__VA_ARGS__>

/**
 * @brief Macro for defining arguments. An argument has an identifier
 *        and a type.
 */
#define ARGUMENT(ARGUMENT_NAME, ARGUMENT_TYPE)   \
  struct ARGUMENT_NAME {                         \
    constexpr static auto name {#ARGUMENT_NAME}; \
    using type = ARGUMENT_TYPE;                  \
    size_t size;                                 \
    char* offset;                                \
  };

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
