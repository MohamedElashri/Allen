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
#include "Argument.cuh"
#include "Datatype.cuh"
#include "MemoryManager.cuh"
#include "AllenBuffer.cuh"
#include <boost/pfr/core.hpp>

namespace Allen::Store {
  class UnorderedStore;

  /**
   * @brief Persistent store that outlives the sequence.
   */
  class PersistentStore {
    friend class UnorderedStore;
    host_memory_manager_t m_mem_manager;
    std::unordered_map<std::string, AllenArgument> m_store {};

  public:
    PersistentStore(const size_t requested_mb, const unsigned required_memory_alignment) :
      m_mem_manager {"Persistent memory manager", requested_mb * 1000 * 1000, required_memory_alignment}
    {}

    PersistentStore(const PersistentStore&) = delete;
    PersistentStore& operator=(const PersistentStore&) = delete;
    PersistentStore(PersistentStore&&) = delete;
    PersistentStore& operator=(PersistentStore&&) = delete;

    const AllenArgument& at(const std::string& k) const
    {
      try {
        return m_store.at(k);
      } catch (std::out_of_range&) {
        error_cout << "Store: key " << k << " not found\n";
        throw;
      }
    }

    template<typename T>
    std::pair<bool, gsl::span<const T>> try_at(const std::string& k) const
    {
      if (m_store.find(k) != std::end(m_store)) {
        return {true, static_cast<gsl::span<const T>>(m_store.at(k))};
      }
      return {false, {}};
    }

    void reserve(AllenArgument& arg)
    {
      if (arg.scope() != Scope::Host) {
        throw std::runtime_error("Persisted arguments must be scope Host");
      }
      m_mem_manager.reserve(arg);
    }

    void free_all() { m_mem_manager.free_all(); }

    void print_memory_manager_states() const { m_mem_manager.print(); }
  };

  /**
   * @brief Allen argument manager
   */
  class UnorderedStore {
    // The host memory manager here is only used for temporaries
    host_memory_manager_t m_host_memory_manager {"Host temporaries memory manager"};
    device_memory_manager_t m_device_memory_manager {"Device memory manager"};
    PersistentStore* m_persistent_store = nullptr;
    std::unordered_map<std::string, AllenArgument> m_store {};
    std::unordered_map<std::string, AllenArgument> m_persistent_store_map {};
    unsigned m_temporary_buffer_counter = 0;

  public:
    UnorderedStore() = default;
    UnorderedStore(const UnorderedStore&) = delete;
    UnorderedStore& operator=(const UnorderedStore&) = delete;
    UnorderedStore(UnorderedStore&&) = delete;
    UnorderedStore& operator=(UnorderedStore&&) = delete;

    void set_persistent_store(PersistentStore* persistent_store) { m_persistent_store = persistent_store; }

    void set_persistent_store_map() { m_persistent_store->m_store = m_persistent_store_map; }

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
      if (m_store.find(k) != std::end(m_store)) {
        return m_store.at(k);
      }
      else if (m_persistent_store_map.find(k) != std::end(m_persistent_store_map)) {
        return m_persistent_store_map.at(k);
      }
      throw std::runtime_error("store does not contain key " + k);
    }

    const AllenArgument& at(const std::string& k) const
    {
      if (m_store.find(k) != std::end(m_store)) {
        return m_store.at(k);
      }
      else if (m_persistent_store_map.find(k) != std::end(m_persistent_store_map)) {
        return m_persistent_store_map.at(k);
      }
      throw std::runtime_error("store does not contain key " + k);
    }

    void register_entry(const std::string& k, AllenArgument&& arg)
    {
      decltype(m_persistent_store_map.try_emplace(k, std::forward<AllenArgument>(arg))) ret;
      if (arg.scope() == Allen::Store::Scope::Host) {
        ret = m_persistent_store_map.try_emplace(k, std::forward<AllenArgument>(arg));
      }
      else if (arg.scope() == Allen::Store::Scope::Device) {
        ret = m_store.try_emplace(k, std::forward<AllenArgument>(arg));
      }
      else {
        throw std::runtime_error("unsupported allen argument scope");
      }
      if (!ret.second) {
        throw std::runtime_error("store register_entry failed, entry already exists");
      }
    }

    void put(const std::string& k)
    {
      AllenArgument& arg = at(k);
      if (arg.scope() == Allen::Store::Scope::Host) {
        m_persistent_store->reserve(arg);
      }
      else if (arg.scope() == Allen::Store::Scope::Device) {
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
      // Only free device
      if (arg.scope() == Allen::Store::Scope::Device) {
        m_device_memory_manager.free(arg);
        arg.set_pointer(nullptr);
      }
    }

    void free_all()
    {
      m_host_memory_manager.free_all();
      m_device_memory_manager.free_all();
      m_persistent_store = nullptr;
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
   * @brief Metaprogramming to extract ::type from each aggregated type.
   */
  template<typename Tuple>
  struct AggregateTypes;

  template<>
  struct AggregateTypes<std::tuple<>> {
    using aggregates_tuple_type_t = std::tuple<>;
  };

  template<typename T, typename... Ts>
  struct AggregateTypes<std::tuple<T, Ts...>> {
    using aggregates_tuple_type_t =
      prepend_to_tuple_t<typename T::type, typename AggregateTypes<std::tuple<Ts...>>::aggregates_tuple_type_t>;
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
    using input_aggregates_t = typename AggregateTypes<InputAggregatesTuple>::aggregates_tuple_type_t;
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
#if defined(ALLEN_STANDALONE) || !defined(TARGET_DEVICE_CPU)
      return m_store->make_buffer<S, T>(size);
#else
      return Allen::buffer<Allen::Store::Scope::Host, T> {size};
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
      return std::get<index_of_v<T, InputAggregatesTuple>>(m_input_aggregates);
    }
  };

  /**
   * @brief Tuple wrapper that extracts tuples out of the
   *        Parameters struct. It extracts a tuple of all parameters and properties
   *        (parameters_and_properties_tuple_t), and a tuple of parameters (parameters_tuple_t).
   */
  template<typename Tuple, typename I, typename Enabled = void>
  struct WrappedTupleDetails;

  template<typename Tuple>
  struct WrappedTupleDetails<Tuple, std::index_sequence<>> {
    using parameters_and_properties_tuple_t = std::tuple<>;
    using parameters_tuple_t = std::tuple<>;
    using aggregates_tuple_t = std::tuple<>;
  };

  template<typename Tuple, std::size_t I, std::size_t... Is>
  struct WrappedTupleDetails<
    Tuple,
    std::index_sequence<I, Is...>,
    std::enable_if_t<(
      std::is_base_of_v<device_datatype, boost::pfr::tuple_element_t<I, Tuple>> ||
      std::is_base_of_v<host_datatype, boost::pfr::tuple_element_t<I, Tuple>>) &&!std::
                       is_base_of_v<aggregate_datatype, boost::pfr::tuple_element_t<I, Tuple>>>> {
    using prev_wrapped_tuple = WrappedTupleDetails<Tuple, std::index_sequence<Is...>>;
    using prev_parameters_and_properties_tuple_t = typename prev_wrapped_tuple::parameters_and_properties_tuple_t;
    using parameters_and_properties_tuple_t =
      prepend_to_tuple_t<boost::pfr::tuple_element_t<I, Tuple>, prev_parameters_and_properties_tuple_t>;
    using prev_parameters_tuple_t = typename prev_wrapped_tuple::parameters_tuple_t;
    using parameters_tuple_t = prepend_to_tuple_t<boost::pfr::tuple_element_t<I, Tuple>, prev_parameters_tuple_t>;
    using aggregates_tuple_t = typename prev_wrapped_tuple::aggregates_tuple_t;
  };

  template<typename Tuple, std::size_t I, std::size_t... Is>
  struct WrappedTupleDetails<
    Tuple,
    std::index_sequence<I, Is...>,
    std::enable_if_t<std::is_base_of_v<aggregate_datatype, boost::pfr::tuple_element_t<I, Tuple>>>> {
    using prev_wrapped_tuple = WrappedTupleDetails<Tuple, std::index_sequence<Is...>>;
    using parameters_and_properties_tuple_t = prepend_to_tuple_t<
      boost::pfr::tuple_element_t<I, Tuple>,
      typename prev_wrapped_tuple::parameters_and_properties_tuple_t>;
    using parameters_tuple_t = typename prev_wrapped_tuple::parameters_tuple_t;
    using aggregates_tuple_t =
      prepend_to_tuple_t<boost::pfr::tuple_element_t<I, Tuple>, typename prev_wrapped_tuple::aggregates_tuple_t>;
  };

  template<typename Tuple, std::size_t I, std::size_t... Is>
  struct WrappedTupleDetails<
    Tuple,
    std::index_sequence<I, Is...>,
    std::enable_if_t<
      !std::is_base_of_v<device_datatype, boost::pfr::tuple_element_t<I, Tuple>> &&
      !std::is_base_of_v<host_datatype, boost::pfr::tuple_element_t<I, Tuple>> &&
      !std::is_base_of_v<aggregate_datatype, boost::pfr::tuple_element_t<I, Tuple>>>> {
    using prev_wrapped_tuple = WrappedTupleDetails<Tuple, std::index_sequence<Is...>>;
    using prev_parameters_and_properties_tuple_t = typename prev_wrapped_tuple::parameters_and_properties_tuple_t;
    using parameters_and_properties_tuple_t =
      prepend_to_tuple_t<boost::pfr::tuple_element_t<I, Tuple>, prev_parameters_and_properties_tuple_t>;
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

  template<typename T>
  using WrappedTuple = WrappedTupleDetails<T, std::make_index_sequence<boost::pfr::tuple_size_v<T>>>;
} // namespace Allen::Store

template<typename T>
using ArgumentReferences = Allen::Store::StoreRef<
  typename Allen::Store::WrappedTuple<T>::parameters_and_properties_tuple_t,
  typename Allen::Store::WrappedTuple<T>::parameters_tuple_t,
  T,
  typename Allen::Store::WrappedTuple<T>::aggregates_tuple_t>;
