#pragma once

#include <tuple>
#include <vector>
#include "CudaCommon.h"
#include "Logger.h"
#include "TupleTools.cuh"
#include "Argument.cuh"

/**
 * @brief Helper class to generate arguments based on
 *        the information provided by the base_pointer and offsets
 */
template<typename Tuple>
struct ArgumentManager {
  Tuple arguments_tuple;
  char* device_base_pointer;
  char* host_base_pointer;

  ArgumentManager() = default;

  void set_base_pointers(
    char* param_device_base_pointer,
    char* param_host_base_pointer) {
    device_base_pointer = param_device_base_pointer;
    host_base_pointer = param_host_base_pointer;
  }

  template<typename T>
  auto begin() const
  {
    auto pointer = tuple_ref_by_inheritance<T>(arguments_tuple).offset;
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T>
  size_t size() const
  {
    return tuple_ref_by_inheritance<T>(arguments_tuple).size;
  }

  template<typename T>
  typename std::enable_if<std::is_base_of<device_datatype, T>::value>::type
  set_offset(const uint offset)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).offset = device_base_pointer + offset;
  }

  template<typename T>
  typename std::enable_if<std::is_base_of<host_datatype, T>::value>::type
  set_offset(const uint offset)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).offset = host_base_pointer + offset;
  }

  template<typename T>
  void set_size(const size_t size)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).size = size * sizeof(typename T::type);
  }
};

/**
 * @brief Manager of argument references for every handler.
 */
template<typename Arguments>
struct ArgumentRefManager;

template<typename... Arguments>
struct ArgumentRefManager<std::tuple<Arguments...>> {
  using TupleToReferences = std::tuple<Arguments&...>;
  TupleToReferences m_arguments;

  ArgumentRefManager(TupleToReferences arguments) : m_arguments(arguments) {}

  template<typename T>
  auto begin() const
  {
    auto pointer = tuple_ref_by_inheritance<T&>(m_arguments).offset;
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T>
  size_t size() const
  {
    return tuple_ref_by_inheritance<T&>(m_arguments).size;
  }

  template<typename T>
  void set_size(const size_t size)
  {
    tuple_ref_by_inheritance<T&>(m_arguments).size = size * sizeof(typename T::type);
  }
};

// Helpers
template<typename Arg, typename Args>
void set_size(Args arguments, const size_t size) {
  arguments.template set_size<Arg>(size);
}

template<typename Arg, typename Args>
size_t size(const Args& arguments) {
  return arguments.template size<Arg>();
}

template<typename Arg, typename Args>
auto begin(const Args& arguments) {
  return Arg{arguments.template begin<Arg>()};
}

template<typename Arg, typename Args>
auto value(const Args& arguments) {
  return Arg{arguments.template begin<Arg>()}[0];
}

// SFINAE for single argument functions, like initialization and print of host / device parameters
template<typename Arg, typename Args, typename Enabled = void>
struct SingleArgumentOverloadResolution;

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<
  Arg,
  Args,
  typename std::enable_if<std::is_base_of<host_datatype, Arg>::value>::type> {
  constexpr static void initialize(const Args& arguments, const int value, cudaStream_t)
  {
    std::memset(begin<Arg>(arguments), value, size<Arg>(arguments));
  }

  constexpr static void print(const Args& arguments, const int value, cudaStream_t)
  {
    const auto array = begin<Arg>(arguments);
    for (uint i = 0; i < size<Arg>(arguments) / sizeof(typename Arg::type); ++i) {
      info_cout << array[i] << ", ";
    }
    info_cout << "\n";
  }
};

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<
  Arg,
  Args,
  typename std::enable_if<std::is_base_of<device_datatype, Arg>::value>::type> {
  constexpr static void initialize(const Args& arguments, const int value, cudaStream_t stream)
  {
    cudaCheck(cudaMemsetAsync(
      begin<Arg>(arguments),
      value,
      size<Arg>(arguments),
      stream));
  }

  constexpr static void print(const Args& arguments, const int value, cudaStream_t)
  {
    std::vector<typename Arg::type> v(size<Arg>(arguments) / sizeof(typename Arg::type));
    cudaCheck(cudaMemcpy(v.data(), begin<Arg>(arguments), size<Arg>(arguments), cudaMemcpyDeviceToHost));

    for (const auto& i : v) {
      info_cout << i << ", ";
    }
    info_cout << "\n";
  }
};

// SFINAE for double argument functions, like copying
// template<typename A, typename B, typename Args, typename Enabled = void>
// struct DoubleArgumentOverloadResolution;

// template<typename A, typename B, typename Args>
// struct DoubleArgumentOverloadResolution<
//   A,
//   B,
//   Args,
//   std::conditional_t<
//     std::is_base_of<host_datatype, A>::value,
//     std::enable_if_t<std::is_base_of<host_datatype, B>::value>,
//     std::enable_if_t<false>>> {
//   constexpr static void copy(const Args& arguments, cudaStream_t)
//   {
//     // std::memset(begin<Arg>(arguments), value, size<Arg>(arguments));
//   }
// };

/**
 * @brief Initializes a datatype with the value specified.
 *        Can be used to either initialize values on the host or on the device.
 * @details On the host, this resolves to a std::memset.
 *          On the device, this resolves to a cudaMemsetAsync. No synchronization
 *          is performed after the initialization.
 */
template<typename Arg, typename Args>
void initialize(const Args& arguments, const int value, cudaStream_t stream = 0) {
  SingleArgumentOverloadResolution<Arg, Args>::initialize(arguments, value, stream);
}

/**
 * @brief Prints the value of an argument.
 * @details On the host, a mere loop and a print statement is done.
 *          On the device, a cudaMemcpy is used to first copy the data onto a std::vector.
 *          Note that as a consequence of this, printing device variables results in a
 *          considerable slowdown.
 */
template<typename Arg, typename Args>
void print(const Args& arguments, const int value) {
  SingleArgumentOverloadResolution<Arg, Args>::print(arguments, value, 0);
}
