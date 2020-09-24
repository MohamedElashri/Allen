/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ArgumentManager.cuh"
#include "Property.cuh"
#include <functional>
#include <utility>
#include <tuple>

template<typename ArgMan, typename P, typename T, typename Enabled = void>
struct ProduceSingleParameter;

template<typename ArgMan, typename P, typename T>
struct ProduceSingleParameter<ArgMan, P, T, typename std::enable_if<std::is_base_of<device_datatype, T>::value || std::is_base_of<host_datatype, T>::value>::type> {
  constexpr static auto produce(ArgMan arguments, P) {
    return data<T>(arguments);
  }
};

template<typename ArgMan, typename P, typename T>
struct ProduceSingleParameter<ArgMan, P, T, typename std::enable_if<!std::is_base_of<device_datatype, T>::value && !std::is_base_of<host_datatype, T>::value>::type> {
  constexpr static auto produce(ArgMan, P class_ptr) {
    return class_ptr->template property<T>();
  }
};

template<typename ArgMan, typename P, typename Tuple>
struct TransformParameterImpl;

template<typename ArgMan, typename P, typename... T>
struct TransformParameterImpl<ArgMan, P, std::tuple<T...>> {
  constexpr static typename ArgMan::parameter_struct_t transform(ArgMan arguments, P class_ptr) {
    return {
      ProduceSingleParameter<ArgMan, P, T>::produce(arguments, class_ptr)...
    };
  }
};

template<typename T>
struct TransformParameter {
  template<typename P>
  constexpr static auto transform(T&& t, P) {
    return std::forward<T>(t);
  }
};

template<typename... T>
struct TransformParameter<const ArgumentRefManager<T...>&> {
  using tuple = typename ArgumentRefManager<T...>::parameter_tuple_t;

  template<typename P>
  constexpr static auto transform(const ArgumentRefManager<T...>& t, P class_ptr) {
    return TransformParameterImpl<ArgumentRefManager<T...>, P, tuple>::transform(t, class_ptr);
  }
};

/**
 * @brief      A Handler that encapsulates a host function.
 *             set_arguments allows to set up the arguments of the function.
 *             invokes calls it.
 */
template<typename P, typename R, typename... T>
struct HostFunction {
private:
  P m_class_ptr;
  std::function<R(T...)> m_fn;

public:
  HostFunction(P class_ptr, std::function<R(T...)> fn) : m_class_ptr(class_ptr), m_fn(fn) {}

  template<typename... S>
  auto operator()(S&&... arguments) const
  {
    return m_fn(TransformParameter<S>::template transform<P>(std::forward<S>(arguments), m_class_ptr)...);
  }
};
