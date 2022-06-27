/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <gsl/gsl>
#include <vector>
#include <cstring>
#include <unordered_map>
#include "BackendCommon.h"
#include "Logger.h"
#include "AllenTypeTraits.h"
#include "StructToTuple.cuh"
#include "Argument.cuh"
#include "Datatype.cuh"

namespace Allen::Store {
  /**
   * @brief Allen argument manager
   */
  class UnorderedStore {
    std::unordered_map<std::string, AllenArgument> m_store;

  public:
    AllenArgument& at(const std::string& k) {
      try {
        return m_store.at(k);
      } catch (std::out_of_range) {
        error_cout << "Store: key " << k << " not found\n";
        throw;
      }
    }

    template<typename T>
    gsl::span<T>& at(const std::string& k) {
      try {
        return m_store.at(k).get<T>();
      } catch (std::out_of_range) {
        error_cout << "Store: key " << k << " not found\n";
        throw;
      }
    }

    void emplace(const std::string& k, AllenArgument&& t)
    {
      const auto& [ret, ok] = m_store.try_emplace(k, std::forward<AllenArgument>(t));
      if (!ok) {
        throw std::runtime_error("store emplace failed, entry already exists");
      }
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
  struct StoreRef {
  public:
    using parameters_and_properties_tuple_t = ParametersAndPropertiesTuple;
    using parameters_tuple_t = ParameterTuple;
    using parameters_struct_t = ParameterStruct;
    using input_aggregates_t = InputAggregatesTuple;
    using store_ref_t = std::array<std::reference_wrapper<BaseArgument>, std::tuple_size_v<parameters_tuple_t>>;

  private:
    mutable store_ref_t m_store_ref;
    input_aggregates_t m_input_aggregates;

  public:
    StoreRef(store_ref_t store_ref, input_aggregates_t input_aggregates) :
      m_store_ref(store_ref), m_input_aggregates(input_aggregates)
    {}

    StoreRef(store_ref_t store_ref) : m_store_ref(store_ref) {}

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    typename T::type* pointer() const
    {
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      auto pointer = m_store_ref[index_of_T].get().pointer();
      return reinterpret_cast<typename T::type*>(pointer);
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    typename T::type first() const
    {
      static_assert(std::is_base_of_v<host_datatype, T> && "first can only access host datatypes");
      if constexpr (std::is_base_of_v<optional_datatype, T>) {
        if (pointer<T>() == nullptr) {
          return 0;
        }
      }
      return pointer<T>()[0];
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    size_t size() const
    {
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      return m_store_ref[index_of_T].get().size();
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    void set_size(const size_t size)
    {
      static_assert(
        !Allen::is_template_base_of_v<input_datatype, T> && "set_size can only be used on output datatypes");
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      m_store_ref[index_of_T].get().set_size(size);
    }

    /**
     * @brief Reduces the size of the container.
     * @details Reducing the size can be done in the operator(), hence this method is const.
     */
    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    void reduce_size(const size_t size) const
    {
      static_assert(
        !Allen::is_template_base_of_v<input_datatype, T> && "reduce_size can only be used on output datatypes");
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      assert(size <= m_store_ref[index_of_T].get().size());
      m_store_ref[index_of_T].get().set_size(size);
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    std::string name() const
    {
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      return m_store_ref[index_of_T].get().name();
    }

    template<typename T, std::enable_if_t<std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    auto input_aggregate() const
    {
      return std::get<T>(m_input_aggregates).value();
    }
  };

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

  template<size_t... Is>
  auto gen_input_aggregates_tuple(
    const std::vector<std::vector<std::reference_wrapper<BaseArgument>>>& input_aggregates,
    std::index_sequence<Is...>)
  {
    return std::make_tuple(input_aggregates[Is]...);
  }

} // namespace Allen::Store

template<typename T>
using ArgumentReferences = Allen::Store::StoreRef<
  typename Allen::Store::WrappedTuple<decltype(struct_to_tuple(T {}))>::parameters_and_properties_tuple_t,
  typename Allen::Store::WrappedTuple<decltype(struct_to_tuple(T {}))>::parameters_tuple_t,
  T,
  typename Allen::Store::WrappedTuple<decltype(struct_to_tuple(T {}))>::aggregates_tuple_t>;
