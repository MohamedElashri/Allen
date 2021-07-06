/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <gsl/gsl>
#include <vector>
#include <cstring>
#include "BackendCommon.h"
#include "Logger.h"
#include "AllenTypeTraits.cuh"
#include "Argument.cuh"
#include "StructToTuple.cuh"

/**
 * @brief Contains the data of an argument, namely its name, data pointer and size.
 *
 */
struct ArgumentData {
private:
  char* m_pointer = nullptr;
  size_t m_size = 0;
  std::string m_name = "";

public:
  virtual char* pointer() const { return m_pointer; }
  virtual size_t size() const { return m_size; }
  virtual std::string name() const { return m_name; }
  virtual void set_pointer(char* pointer) { m_pointer = pointer; }
  virtual void set_size(size_t size) { m_size = size; }
  virtual void set_name(const std::string& name) { m_name = name; }
  virtual ~ArgumentData() {}
};

/**
 * @brief Holds a database of arguments, and provides accessors for their pointers and size.
 */
template<typename Tuple>
struct ArgumentManager {
private:
  std::array<ArgumentData, std::tuple_size_v<Tuple>> m_tuple_to_argument_data;

public:
  std::array<ArgumentData, std::tuple_size_v<Tuple>>& argument_database() { return m_tuple_to_argument_data; }

  template<typename T>
  typename T::type* pointer() const
  {
    constexpr auto index_of_T = index_of_v<T, Tuple>;
    static_assert(index_of_T < std::tuple_size_v<Tuple> && "Index of T is in bounds");
    auto pointer = m_tuple_to_argument_data[index_of_T].pointer();
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T>
  void set_pointer(char* pointer)
  {
    constexpr auto index_of_T = index_of_v<T, Tuple>;
    static_assert(index_of_T < std::tuple_size_v<Tuple> && "Index of T is in bounds");
    m_tuple_to_argument_data[index_of_T].set_pointer(pointer);
  }

  template<typename T>
  size_t size() const
  {
    constexpr auto index_of_T = index_of_v<T, Tuple>;
    static_assert(index_of_T < std::tuple_size_v<Tuple> && "Index of T is in bounds");
    return m_tuple_to_argument_data[index_of_T].size();
  }

  template<typename T>
  void set_size(const size_t size)
  {
    static_assert(!Allen::isDerivedFrom<input_datatype, T>::value && "set_size can only be used on output datatypes");
    constexpr auto index_of_T = index_of_v<T, Tuple>;
    static_assert(index_of_T < std::tuple_size_v<Tuple> && "Index of T is in bounds");
    m_tuple_to_argument_data[index_of_T].set_size(size);
  }

  template<typename T>
  std::string name() const
  {
    constexpr auto index_of_T = index_of_v<T, Tuple>;
    static_assert(index_of_T < std::tuple_size_v<Tuple> && "Index of T is in bounds");
    return m_tuple_to_argument_data[index_of_T].name();
  }

  template<typename T>
  void set_name(const std::string& name)
  {
    constexpr auto index_of_T = index_of_v<T, Tuple>;
    static_assert(index_of_T < std::tuple_size_v<Tuple> && "Index of T is in bounds");
    return m_tuple_to_argument_data[index_of_T].set_name(name);
  }
};

/**
 * @brief Manager of argument references for every handler.
 */
template<
  typename ParametersAndPropertiesTuple,
  typename ParameterTuple,
  typename ParameterStruct,
  typename InputAggregatesTuple = std::tuple<>>
struct ArgumentRefManager {
public:
  using parameters_and_properties_tuple_t = ParametersAndPropertiesTuple;
  using parameters_tuple_t = ParameterTuple;
  using parameters_struct_t = ParameterStruct;
  using input_aggregates_t = InputAggregatesTuple;

private:
  mutable std::array<std::reference_wrapper<ArgumentData>, std::tuple_size_v<parameters_tuple_t>>
    m_tuple_to_argument_data;
  input_aggregates_t m_input_aggregates;

public:
  ArgumentRefManager(
    std::array<std::reference_wrapper<ArgumentData>, std::tuple_size_v<parameters_tuple_t>> tuple_to_argument_data,
    input_aggregates_t input_aggregates) :
    m_tuple_to_argument_data(tuple_to_argument_data),
    m_input_aggregates(input_aggregates)
  {}

  ArgumentRefManager(
    std::array<std::reference_wrapper<ArgumentData>, std::tuple_size_v<parameters_tuple_t>> tuple_to_argument_data) :
    m_tuple_to_argument_data(tuple_to_argument_data)
  {}

  template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
  typename T::type* pointer() const
  {
    constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
    static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
    auto pointer = m_tuple_to_argument_data[index_of_T].get().pointer();
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
  typename T::type first() const
  {
    static_assert(std::is_base_of_v<host_datatype, T> && "first can only access host datatypes");
    return pointer<T>()[0];
  }

  template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
  size_t size() const
  {
    constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
    static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
    return m_tuple_to_argument_data[index_of_T].get().size();
  }

  template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
  void set_size(const size_t size)
  {
    static_assert(!Allen::isDerivedFrom<input_datatype, T>::value && "set_size can only be used on output datatypes");
    constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
    static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
    m_tuple_to_argument_data[index_of_T].get().set_size(size);
  }

  /**
   * @brief Reduces the size of the container.
   * @details Reducing the size can be done in the operator(), hence this method is const.
   */
  template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
  void reduce_size(const size_t size) const
  {
    static_assert(
      !Allen::isDerivedFrom<input_datatype, T>::value && "reduce_size can only be used on output datatypes");
    constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
    static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
    assert(size <= m_tuple_to_argument_data[index_of_T].get().size());
    m_tuple_to_argument_data[index_of_T].get().set_size(size);
  }

  template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
  std::string name() const
  {
    constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
    static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
    return m_tuple_to_argument_data[index_of_T].get().name();
  }

  template<typename T, std::enable_if_t<std::is_base_of_v<aggregate_datatype, T>, bool> = true>
  auto input_aggregate() const
  {
    return std::get<T>(m_input_aggregates).value();
  }
};

/**
 * @brief Aggregate datatype
 */
template<typename T>
struct InputAggregate {
private:
  std::vector<std::reference_wrapper<ArgumentData>> m_argument_data_v;

public:
  using type = T;

  InputAggregate() = default;

  InputAggregate(const std::vector<std::reference_wrapper<ArgumentData>>& argument_data_v) :
    m_argument_data_v(argument_data_v)
  {}

  template<typename Tuple, std::size_t... Is>
  InputAggregate(Tuple t, std::index_sequence<Is...>) : m_argument_data_v {std::get<Is>(t)...}
  {}

  T* data(const unsigned index) const
  {
    assert(index < m_argument_data_v.size() && "Index is in bounds");
    auto pointer = m_argument_data_v[index].get().pointer();
    return reinterpret_cast<T*>(pointer);
  }

  T first(const unsigned index) const
  {
    assert(index < m_argument_data_v.size() && "Index is in bounds");
    return data(index)[0];
  }

  size_t size(const unsigned index) const
  {
    assert(index < m_argument_data_v.size() && "Index is in bounds");
    return m_argument_data_v[index].get().size();
  }

  gsl::span<T> span(const unsigned index) const { return {data(index), size(index)}; }

  std::string name(const unsigned index) const
  {
    assert(index < m_argument_data_v.size() && "Index is in bounds");
    return m_argument_data_v[index].get().name();
  }

  size_t size_of_aggregate() const { return m_argument_data_v.size(); }
};

template<typename T, typename... Ts>
static auto makeInputAggregate(std::tuple<Ts&...> tp)
{
  return InputAggregate<T> {tp, std::make_index_sequence<sizeof...(Ts)>()};
}

// Macro
#define INPUT_AGGREGATE(HOST_DEVICE, ARGUMENT_NAME, ...)                                             \
  struct ARGUMENT_NAME : public aggregate_datatype, HOST_DEVICE {                                    \
    using type = InputAggregate<__VA_ARGS__>;                                                        \
    void parameter(__VA_ARGS__) const {}                                                             \
    using deps = std::tuple<>;                                                                       \
    ARGUMENT_NAME() = default;                                                                       \
    ARGUMENT_NAME(const type& input_aggregate) : m_value(input_aggregate) {}                         \
    template<typename... Ts>                                                                         \
    ARGUMENT_NAME(std::tuple<Ts&...> value) : m_value(makeInputAggregate<__VA_ARGS__, Ts...>(value)) \
    {}                                                                                               \
    const type& value() const { return m_value; }                                                    \
                                                                                                     \
  private:                                                                                           \
    type m_value {};                                                                                 \
  }

#define HOST_INPUT_AGGREGATE(ARGUMENT_NAME, ...) INPUT_AGGREGATE(host_datatype, ARGUMENT_NAME, __VA_ARGS__)

#define DEVICE_INPUT_AGGREGATE(ARGUMENT_NAME, ...) INPUT_AGGREGATE(device_datatype, ARGUMENT_NAME, __VA_ARGS__)

/**
 * @brief Tuple wrapper that extracts tuples out of the
 *        Parameters struct. It extracts a tuple of all parameters and properties
 *        (parameters_and_properties_tuple_t), and a tuple of parameters (parameters_tuple_t).
 */
template<typename Tuple, typename Enabled = void>
struct WrappedTuple;

template<>
struct WrappedTuple<std::tuple<>, void> {
  using parameters_and_properties_tuple_t = std::tuple<>;
  using parameters_tuple_t = std::tuple<>;
  using aggregates_tuple_t = std::tuple<>;
};

template<typename T, typename... R>
struct WrappedTuple<
  std::tuple<T, R...>,
  std::enable_if_t<(std::is_base_of_v<device_datatype, T> || std::is_base_of_v<host_datatype, T>) &&!std::
                     is_base_of_v<aggregate_datatype, T>>> {
  using prev_wrapped_tuple = WrappedTuple<std::tuple<R...>>;
  using prev_parameters_and_properties_tuple_t = typename prev_wrapped_tuple::parameters_and_properties_tuple_t;
  using parameters_and_properties_tuple_t = prepend_to_tuple_t<T, prev_parameters_and_properties_tuple_t>;
  using prev_parameters_tuple_t = typename prev_wrapped_tuple::parameters_tuple_t;
  using parameters_tuple_t = prepend_to_tuple_t<T, prev_parameters_tuple_t>;
  using aggregates_tuple_t = typename prev_wrapped_tuple::aggregates_tuple_t;
};

template<typename T, typename... R>
struct WrappedTuple<std::tuple<T, R...>, std::enable_if_t<std::is_base_of_v<aggregate_datatype, T>>> {
  using prev_wrapped_tuple = WrappedTuple<std::tuple<R...>>;
  using parameters_and_properties_tuple_t =
    prepend_to_tuple_t<T, typename prev_wrapped_tuple::parameters_and_properties_tuple_t>;
  using parameters_tuple_t = typename prev_wrapped_tuple::parameters_tuple_t;
  using aggregates_tuple_t = prepend_to_tuple_t<T, typename prev_wrapped_tuple::aggregates_tuple_t>;
};

template<typename T, typename... R>
struct WrappedTuple<
  std::tuple<T, R...>,
  std::enable_if_t<
    !std::is_base_of_v<device_datatype, T> && !std::is_base_of_v<host_datatype, T> &&
    !std::is_base_of_v<aggregate_datatype, T>>> {
  using prev_wrapped_tuple = WrappedTuple<std::tuple<R...>>;
  using prev_parameters_and_properties_tuple_t = typename prev_wrapped_tuple::parameters_and_properties_tuple_t;
  using parameters_and_properties_tuple_t = prepend_to_tuple_t<T, prev_parameters_and_properties_tuple_t>;
  using parameters_tuple_t = typename prev_wrapped_tuple::parameters_tuple_t;
  using aggregates_tuple_t = typename prev_wrapped_tuple::aggregates_tuple_t;
};

template<typename T>
using ArgumentReferences = ArgumentRefManager<
  typename WrappedTuple<decltype(struct_to_tuple(T {}))>::parameters_and_properties_tuple_t,
  typename WrappedTuple<decltype(struct_to_tuple(T {}))>::parameters_tuple_t,
  T,
  typename WrappedTuple<decltype(struct_to_tuple(T {}))>::aggregates_tuple_t>;
