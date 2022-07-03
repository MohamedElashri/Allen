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
#include "MemoryManager.cuh"
#include "AllenBuffer.cuh"

namespace Allen::Store {
  /**
   * @brief Allen argument manager
   */
  class UnorderedStore {
    host_memory_manager_t m_host_memory_manager {"Host memory manager"};
    device_memory_manager_t m_device_memory_manager {"Device memory manager"};
    std::unordered_map<std::string, AllenArgument> m_store {};
    unsigned m_temporary_buffer_counter = 0;

  public:
    UnorderedStore() = default;
    UnorderedStore(const UnorderedStore&) = delete;
    UnorderedStore& operator=(const UnorderedStore&) = delete;
    UnorderedStore(UnorderedStore&&) = delete;
    UnorderedStore& operator=(UnorderedStore&&) = delete;

    template<Scope S, typename T>
    auto make_buffer(const size_t size)
    {
      if constexpr (S == Scope::Host) {
        return Allen::buffer<S, T> {
          m_host_memory_manager, "temp_" + std::to_string(m_temporary_buffer_counter++), size};
      }
      else {
        return Allen::buffer<S, T> {
          m_device_memory_manager, "temp_" + std::to_string(m_temporary_buffer_counter++), size};
      }
    }

    AllenArgument& at(const std::string& k)
    {
      try {
        return m_store.at(k);
      } catch (std::out_of_range&) {
        error_cout << "Store: key " << k << " not found\n";
        throw;
      }
    }

    const AllenArgument& at(const std::string& k) const
    {
      try {
        return m_store.at(k);
      } catch (std::out_of_range&) {
        error_cout << "Store: key " << k << " not found\n";
        throw;
      }
    }

    void register_entry(const std::string& k, AllenArgument&& t)
    {
      const auto& [ret, ok] = m_store.try_emplace(k, std::forward<AllenArgument>(t));
      if (!ok) {
        throw std::runtime_error("store register_entry failed, entry already exists");
      }
    }

    void put(const std::string& k)
    {
      AllenArgument& arg = at(k);
      if (arg.scope() == m_host_memory_manager.scope) {
        m_host_memory_manager.reserve(arg);
      }
      else if (arg.scope() == m_device_memory_manager.scope) {
        m_device_memory_manager.reserve(arg);
      }
      else {
        throw std::runtime_error("argument scope not recognized");
      }
    }

    void reserve_memory_host(const size_t requested_mb, const unsigned required_memory_alignment)
    {
      m_host_memory_manager.reserve_memory(requested_mb * 1000 * 1000, required_memory_alignment);
    }

    void reserve_memory_device(const size_t requested_mb, const unsigned required_memory_alignment)
    {
      m_device_memory_manager.reserve_memory(requested_mb * 1000 * 1000, required_memory_alignment);
    }

    void free(const std::string& k)
    {
      auto& arg = at(k);
      // Do not free host arguments
      if (arg.scope() == m_device_memory_manager.scope) {
        m_device_memory_manager.free(arg);
        arg.set_pointer(nullptr);
      }
      else if (arg.scope() != m_host_memory_manager.scope) {
        throw std::runtime_error("argument scope not recognized");
      }
    }

    void free_all()
    {
      m_host_memory_manager.free_all();
      m_device_memory_manager.free_all();
      m_temporary_buffer_counter = 0;
    }

    void reset()
    {
      m_store.clear();
      free_all();
    }

    void print_memory_manager_states() const
    {
      m_host_memory_manager.print();
      m_device_memory_manager.print();
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
    using arguments_t = std::array<std::reference_wrapper<BaseArgument>, std::tuple_size_v<parameters_tuple_t>>;

  private:
    mutable arguments_t m_arguments;
    input_aggregates_t m_input_aggregates;
    UnorderedStore* m_store;

  public:
    StoreRef(arguments_t arguments, input_aggregates_t input_aggregates, UnorderedStore& store) :
      m_arguments(arguments), m_input_aggregates(input_aggregates), m_store(&store)
    {}

    StoreRef(arguments_t arguments, input_aggregates_t input_aggregates) :
      m_arguments(arguments), m_input_aggregates(input_aggregates)
    {}

    StoreRef(arguments_t arguments) : m_arguments(arguments) {}

    template<Scope S, typename T>
    auto make_buffer(const size_t size) const
    {
#if ALLEN_STANDALONE
      return m_store->make_buffer<S, T>(size);
#else
      return std::vector<T>(size);
#endif
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    gsl::span<typename T::type> get() const
    {
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      return m_arguments[index_of_T].get();
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    auto data() const
    {
      return get<T>().data();
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    auto first() const
    {
      static_assert(std::is_base_of_v<host_datatype, T> && "first can only access host datatypes");
      static_assert(!std::is_base_of_v<optional_datatype, T> && "first can only access non-optional datatypes");
      return get<T>()[0];
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    auto size() const
    {
      return get<T>().size();
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    void set_size(const size_t size)
    {
      static_assert(
        !Allen::is_template_base_of_v<input_datatype, T> && "set_size can only be used on output datatypes");
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      m_arguments[index_of_T].get().set_size(size);
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
      assert(size <= m_arguments[index_of_T].get().operator gsl::span<typename T::type>().size());
      m_arguments[index_of_T].get().set_size(size);
    }

    template<typename T, std::enable_if_t<!std::is_base_of_v<aggregate_datatype, T>, bool> = true>
    std::string name() const
    {
      constexpr auto index_of_T = index_of_v<T, parameters_tuple_t>;
      static_assert(index_of_T < std::tuple_size_v<parameters_tuple_t> && "Index of T is in bounds");
      return m_arguments[index_of_T].get().name();
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
