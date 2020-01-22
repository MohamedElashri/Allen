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

  template<typename T>
  void print() const
  {
    std::vector<typename T::type> v(size<T>() / sizeof(typename T::type));
    cudaCheck(cudaMemcpy(v.data(), begin<T>(), size<T>(), cudaMemcpyDeviceToHost));

    // info_cout << T::name << ": ";
    for (const auto& i : v) {
      info_cout << i << ", ";
    }
    info_cout << "\n";
  }
};

// Helpers
template<typename Arg, typename Args>
size_t size(Args arguments) {
  return arguments.template size<Arg>();
}

template<typename Arg, typename Args>
void set_size(Args arguments, const size_t size) {
  arguments.template set_size<Arg>(size);
}

template<typename Arg, typename Args>
auto begin(const Args& arguments) {
  return Arg{arguments.template begin<Arg>()};
}

template<typename Arg, typename Args>
auto value(const Args& arguments) {
  return Arg{arguments.template begin<Arg>()}[0];
}

template<typename Arg, typename Args>
void print(Args arguments) {
  arguments.template print<Arg>();
}
