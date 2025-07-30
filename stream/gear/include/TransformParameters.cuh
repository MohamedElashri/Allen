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

#include "Store.cuh"
#include "ArgumentOps.cuh"
#include "BackendCommon.h"
#include "BaseTypes.cuh"
#include <functional>
#include <utility>
#include <tuple>
#include <type_traits>

/**
 * @brief Produces a single parameter. Uses SFINAE to choose the returned object.
 */
template<typename ArgMan, typename T, typename Enabled = void>
struct ProduceSingleParameter;

/**
 * @brief Produces device or host datatypes.
 */
template<typename ArgMan, typename T>
struct ProduceSingleParameter<
  ArgMan,
  T,
  std::enable_if_t<(
    std::is_base_of_v<Allen::Store::device_datatype, T> ||
    std::is_base_of_v<Allen::Store::host_datatype, T>) &&!std::is_base_of_v<Allen::Store::aggregate_datatype, T>>> {
  constexpr static auto produce(const ArgMan& arguments, const Allen::KernelInvocationConfiguration&)
  {
    return arguments.template get<T>();
  }
};

/**
 * @brief Produces aggregate datatypes.
 */
template<typename ArgMan, typename T>
struct ProduceSingleParameter<ArgMan, T, std::enable_if_t<std::is_base_of_v<Allen::Store::aggregate_datatype, T>>> {
  constexpr static auto produce(const ArgMan&, const Allen::KernelInvocationConfiguration&) { return T {}; }
};

/**
 * @brief Produces KernelInvocationConfiguration.
 */
template<typename ArgMan, typename T>
struct ProduceSingleParameter<ArgMan, T, std::enable_if_t<std::is_same_v<Allen::KernelInvocationConfiguration, T>>> {
  constexpr static auto produce(const ArgMan&, const Allen::KernelInvocationConfiguration& config) { return config; }
};

template<typename ArgMan, typename Tuple>
struct TransformParametersImpl;

template<typename ArgMan, typename... T>
struct TransformParametersImpl<ArgMan, std::tuple<T...>> {
  constexpr static typename ArgMan::parameters_struct_t transform(
    const ArgMan& arguments,
    const Allen::KernelInvocationConfiguration& config)
  {
    return {ProduceSingleParameter<ArgMan, T>::produce(arguments, config)...};
  }
};

/**
 * @brief Transforms the parameters tuple into
 *        a Parameters struct. Constructs the Parameters object with
 *        device and host parameters.
 *
 *        This bit of code permits to specify an object of type ArgumentManager where an
 *        object of type Parameters is expected.
 */
template<typename T>
struct TransformParameters {
  constexpr static auto transform(T&& t, const Allen::KernelInvocationConfiguration&) { return std::forward<T>(t); }
};

/**
 * @brief Full specialization for const Allen::Store::StoreRef<T...>&.
 */
template<typename... T>
struct TransformParameters<const Allen::Store::StoreRef<T...>&> {
  constexpr static auto transform(
    const Allen::Store::StoreRef<T...>& t,
    const Allen::KernelInvocationConfiguration& config)
  {
    return TransformParametersImpl<
      Allen::Store::StoreRef<T...>,
      typename Allen::Store::StoreRef<T...>::unaltered_parameters_tuple_t>::transform(t, config);
  }
};
