#pragma once

#include <tuple>
#include <vector>
#include "CudaCommon.h"
#include "Logger.h"
#include "TupleTools.cuh"

/**
 * @brief Helper class to generate arguments based on
 *        the information provided by the base_pointer and offsets
 */
template<typename Tuple>
struct ArgumentManager {
  typename std::tuple_element<0, Tuple>::type a {};
  typename std::tuple_element<1, Tuple>::type b {};

  Tuple arguments_tuple {};
  char* base_pointer;

  ArgumentManager() = default;

  void set_base_pointer(char* param_base_pointer) { base_pointer = param_base_pointer; }

  template<typename T>
  auto offset() const
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
  void set_offset(const uint offset)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).offset = base_pointer + offset;
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
  auto offset() const
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
    cudaCheck(cudaMemcpy(v.data(), offset<T>(), size<T>(), cudaMemcpyDeviceToHost));

    info_cout << T::name << ": ";
    for (const auto& i : v) {
      info_cout << i << ", ";
    }
    info_cout << std::endl;
  }
};

// Helpers
template<typename Arg, typename Args>
auto offset(const Args& arguments) {
  return Arg{arguments.template offset<Arg>()};
}

template<typename Arg, typename Args>
size_t size(const Args& arguments) {
  return arguments.template size<Arg>();
}

template<typename Arg, typename Args>
void set_size(Args arguments, const size_t size) {
  arguments.template set_size<Arg>(size);
}