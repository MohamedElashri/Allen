/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ArgumentManager.cuh"
#include "BackendCommon.h"
#include "Property.cuh"
#include <functional>
#include <utility>
#include <tuple>
#include <type_traits>

/**
 * @brief Produces a single parameter. Uses SFINAE to choose the returned object.
 */
template<typename ArgMan, typename P, typename T, typename Enabled = void>
struct ProduceSingleParameter;

/**
 * @brief Produces device or host datatypes.
 */
template<typename ArgMan, typename P, typename T>
struct ProduceSingleParameter<
  ArgMan,
  P,
  T,
  typename std::enable_if_t<
    std::is_base_of_v<device_datatype, T> || std::is_base_of_v<host_datatype, T>>> {
  constexpr static auto produce(const ArgMan& arguments, P) { return data<T>(arguments); }
};

/**
 * @brief Produces properties.
 */
template<typename ArgMan, typename P, typename T>
struct ProduceSingleParameter<
  ArgMan,
  P,
  T,
  typename std::enable_if_t<
    !std::is_base_of_v<device_datatype, T> && !std::is_base_of_v<host_datatype, T>>> {
  constexpr static auto produce(const ArgMan&, P class_ptr) { return class_ptr->template property<T>(); }
};

template<typename ArgMan, typename P, typename Tuple>
struct TransformParametersImpl;

template<typename ArgMan, typename P, typename... T>
struct TransformParametersImpl<ArgMan, P, std::tuple<T...>> {
  constexpr static typename ArgMan::parameters_struct_t transform(const ArgMan& arguments, P class_ptr)
  {
    return {ProduceSingleParameter<ArgMan, P, T>::produce(arguments, class_ptr)...};
  }
};

/**
 * @brief Transforms the parameters and properties tuple into
 *        a Parameters struct. Constructs the Parameters object with
 *        device and host parameters and properties.
 *
 *        This bit of code permits to specify an object of type ArgumentManager where an
 *        object of type Parameters is expected.
 */
template<typename T>
struct TransformParameters {
  template<typename P>
  constexpr static auto transform(T&& t, P)
  {
    return std::forward<T>(t);
  }
};

/**
 * @brief Full specialization for const ArgumentRefManager<T...>&.
 */
template<typename... T>
struct TransformParameters<const ArgumentRefManager<T...>&> {
  template<typename P>
  constexpr static auto transform(const ArgumentRefManager<T...>& t, P class_ptr)
  {
    return TransformParametersImpl<
      ArgumentRefManager<T...>,
      P,
      typename ArgumentRefManager<T...>::parameters_and_properties_tuple_t>::transform(t, class_ptr);
  }
};
