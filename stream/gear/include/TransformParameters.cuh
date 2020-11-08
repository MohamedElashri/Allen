/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ArgumentManager.cuh"
#include "BackendCommon.h"
#include "BaseTypes.cuh"
#include "Property.cuh"
#include <functional>
#include <utility>
#include <tuple>
#include <type_traits>

namespace Allen {
  template<typename V>
  class Property;
}

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
  typename std::enable_if_t<std::is_base_of_v<device_datatype, T> || std::is_base_of_v<host_datatype, T>>> {
  constexpr static auto produce(const ArgMan& arguments, const std::map<std::string, Allen::BaseProperty*>&)
  {
    return data<T>(arguments);
  }
};

/**
 * @brief Produces properties.
 */
template<typename ArgMan, typename T>
struct ProduceSingleParameter<
  ArgMan,
  T,
  typename std::enable_if_t<!std::is_base_of_v<device_datatype, T> && !std::is_base_of_v<host_datatype, T>>> {
  constexpr static auto produce(const ArgMan&, const std::map<std::string, Allen::BaseProperty*>& properties)
  {
    if (properties.find(T::name) == properties.end()) {
      throw std::runtime_error {"property " + std::string(T::name) + " not found"};
    }

    const auto base_prop = properties.at(T::name);
    const auto prop = dynamic_cast<const Allen::Property<T>*>(base_prop);
    return prop->get_value();
  }
};

template<typename ArgMan, typename Tuple>
struct TransformParametersImpl;

template<typename ArgMan, typename... T>
struct TransformParametersImpl<ArgMan, std::tuple<T...>> {
  constexpr static typename ArgMan::parameters_struct_t transform(
    const ArgMan& arguments,
    const std::map<std::string, Allen::BaseProperty*>& properties)
  {
    return {ProduceSingleParameter<ArgMan, T>::produce(arguments, properties)...};
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
  constexpr static auto transform(T&& t, const std::map<std::string, Allen::BaseProperty*>&)
  {
    return std::forward<T>(t);
  }
};

/**
 * @brief Full specialization for const ArgumentRefManager<T...>&.
 */
template<typename... T>
struct TransformParameters<const ArgumentRefManager<T...>&> {
  constexpr static auto transform(
    const ArgumentRefManager<T...>& t,
    const std::map<std::string, Allen::BaseProperty*>& properties)
  {
    return TransformParametersImpl<
      ArgumentRefManager<T...>,
      typename ArgumentRefManager<T...>::parameters_and_properties_tuple_t>::transform(t, properties);
  }
};
