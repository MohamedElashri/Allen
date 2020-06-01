/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <vector>
#include <cstring>
#include "BackendCommon.h"
#include "Logger.h"
#include "TupleTools.cuh"
#include "Argument.cuh"
#include "ArgumentOps.cuh"

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

  void set_base_pointers(char* param_device_base_pointer, char* param_host_base_pointer)
  {
    device_base_pointer = param_device_base_pointer;
    host_base_pointer = param_host_base_pointer;
  }

  template<typename T>
  auto data() const
  {
    auto pointer = tuple_ref_by_inheritance<T>(arguments_tuple).offset();
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T>
  size_t size() const
  {
    return tuple_ref_by_inheritance<T>(arguments_tuple).size();
  }

  template<typename T>
  std::string name() const
  {
    return tuple_ref_by_inheritance<T>(arguments_tuple).name();
  }

  template<typename T>
  typename std::enable_if<std::is_base_of<device_datatype, T>::value>::type set_offset(const unsigned offset)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).set_offset(device_base_pointer + offset);
  }

  template<typename T>
  typename std::enable_if<std::is_base_of<host_datatype, T>::value>::type set_offset(const unsigned offset)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).set_offset(host_base_pointer + offset);
  }

  template<typename T>
  void set_size(const size_t size)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).set_size(size);
  }
};

/**
 * @brief Manager of argument references for every handler.
 */
template<typename TupleToReferences, typename ParameterTuple = void, typename ParameterStruct = void>
struct ArgumentRefManager {
  using parameter_tuple_t = ParameterTuple;
  using parameter_struct_t = ParameterStruct;
  using tuple_to_references_t = TupleToReferences;

  TupleToReferences m_arguments;

  ArgumentRefManager(TupleToReferences arguments) : m_arguments(arguments) {}

  template<typename T>
  auto data() const
  {
    auto pointer = std::get<T&>(m_arguments).offset();
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T>
  auto first() const
  {
    return data<T>()[0];
  }

  template<typename T>
  size_t size() const
  {
    return std::get<T&>(m_arguments).size();
  }

  template<typename T>
  void set_size(const size_t size)
  {
    std::get<T&>(m_arguments).set_size(size);
  }

  template<typename T>
  std::string name() const
  {
    return std::get<T&>(m_arguments).name();
  }
};

// Wraps tuple arguments
template<typename Tuple, typename Enabled = void>
struct WrappedTuple;

template<>
struct WrappedTuple<std::tuple<>, void> {
  using t = std::tuple<>;
  using parameter_tuple_t = std::tuple<>;
};

template<typename T, typename... R>
struct WrappedTuple<std::tuple<T, R...>,
  typename std::enable_if<std::is_base_of<aggregate_datatype, T>::value>::type> {
  using previous_t = typename WrappedTuple<std::tuple<R...>>::t;
  using t = typename ConcatTupleReferences<typename T::type, previous_t>::t;
  using previous_parameter_tuple_t = typename WrappedTuple<std::tuple<R...>>::parameter_tuple_t;
  using parameter_tuple_t = typename ConcatTuple<typename T::type, previous_parameter_tuple_t>::t;
};

template<typename T, typename... R>
struct WrappedTuple<
  std::tuple<T, R...>,
  typename std::enable_if<
    !std::is_base_of<aggregate_datatype, T>::value &&
    (std::is_base_of<device_datatype, T>::value || std::is_base_of<host_datatype, T>::value)>::type> {
  using previous_t = typename WrappedTuple<std::tuple<R...>>::t;
  using t = typename TupleAppendFirst<T&, previous_t>::t;
  using previous_parameter_tuple_t = typename WrappedTuple<std::tuple<R...>>::parameter_tuple_t;
  using parameter_tuple_t = typename TupleAppendFirst<T, previous_parameter_tuple_t>::t;
};

template<typename T, typename... R>
struct WrappedTuple<
  std::tuple<T, R...>,
  typename std::enable_if<
    !std::is_base_of<device_datatype, T>::value && !std::is_base_of<host_datatype, T>::value>::type> {
  using t = typename WrappedTuple<std::tuple<R...>>::t;
  using previous_parameter_tuple_t = typename WrappedTuple<std::tuple<R...>>::parameter_tuple_t;
  using parameter_tuple_t = typename TupleAppendFirst<T, previous_parameter_tuple_t>::t;
};

template<typename T>
struct ParameterTuple {
  using t = typename WrappedTuple<decltype(
    boost::hana::to<boost::hana::ext::std::tuple_tag>(boost::hana::members(std::declval<T>())))>::t;
};

template<typename T>
using ArgumentReferences = ArgumentRefManager<
  typename WrappedTuple<decltype(
    boost::hana::to<boost::hana::ext::std::tuple_tag>(boost::hana::members(std::declval<T>())))>::t,
  typename WrappedTuple<decltype(
    boost::hana::to<boost::hana::ext::std::tuple_tag>(boost::hana::members(std::declval<T>())))>::parameter_tuple_t,
  T>;
