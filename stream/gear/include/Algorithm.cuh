/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "Logger.h"
#include "BaseTypes.cuh"
#include "TargetFunction.cuh"
#include "Datatype.cuh"
#include "Contract.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "nlohmann/json.hpp"
#include <any>

#ifndef ALLEN_STANDALONE
#include "ServiceLocator.h"
#include "Gaudi/MonitoringHub.h"
#endif

namespace {
  // Get the StoreRefType from the function operator()
  template<typename Function>
  struct FunctionTraits;

  template<typename Function, typename... Ts, typename... OtherArguments>
  struct FunctionTraits<void (Function::*)(const Allen::Store::StoreRef<Ts...>&, OtherArguments...) const> {
    using StoreRefType = Allen::Store::StoreRef<Ts...>;
  };

  template<typename Algorithm>
  struct AlgorithmTraits {
    using StoreRefType = typename FunctionTraits<decltype(&Algorithm::operator())>::StoreRefType;
  };

  // Creates a std::array store out of the vector one
  template<std::size_t... Is>
  auto create_store_ref(
    const std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>& vector_store_ref,
    std::index_sequence<Is...>)
  {
    return std::array {vector_store_ref[Is]...};
  }

  template<typename T, std::size_t I>
  bool emplace_output_arg(const std::vector<std::string>& arguments, Allen::Store::UnorderedStore& store)
  {
    using t = std::tuple_element_t<I, T>;
    if constexpr (Allen::is_template_base_of_v<Allen::Store::output_datatype, t>) {
      store.register_entry(
        arguments[I],
        Allen::Store::AllenArgument {std::in_place_type<typename t::type>,
                                     arguments[I],
                                     std::is_base_of_v<Allen::Store::host_datatype, t> ? Allen::Store::Scope::Host :
                                                                                         Allen::Store::Scope::Device});
    }
    else {
      _unused(arguments);
      _unused(store);
    }
    return true;
  }

  template<typename T, std::size_t... Is>
  void emplace_output_argument(
    const std::vector<std::string>& arguments,
    Allen::Store::UnorderedStore& store,
    std::index_sequence<Is...>)
  {
    (emplace_output_arg<T, Is>(arguments, store) && ...);
  }
} // namespace

namespace Allen {
  template<typename ContractsTuple, typename Enabled = void>
  struct AlgorithmContracts;

  template<>
  struct AlgorithmContracts<std::tuple<>, void> {
    using preconditions = std::tuple<>;
    using postconditions = std::tuple<>;
  };

  template<typename A, typename... T>
  struct AlgorithmContracts<
    std::tuple<A, T...>,
    std::enable_if_t<std::is_base_of_v<Allen::contract::Precondition, A>>> {
    using recursive_contracts = AlgorithmContracts<std::tuple<T...>>;
    using preconditions = append_to_tuple_t<typename recursive_contracts::preconditions, A>;
    using postconditions = typename recursive_contracts::postconditions;
  };

  template<typename A, typename... T>
  struct AlgorithmContracts<
    std::tuple<A, T...>,
    std::enable_if_t<std::is_base_of_v<Allen::contract::Postcondition, A>>> {
    using recursive_contracts = AlgorithmContracts<std::tuple<T...>>;
    using preconditions = typename recursive_contracts::preconditions;
    using postconditions = append_to_tuple_t<typename recursive_contracts::postconditions, A>;
  };

#if __GNUC__ == 11
// Deal with spurious -Wnonnull from GCC 11 dbg builds
// Perhaps https://gcc.gnu.org/bugzilla/show_bug.cgi?id=96003
#pragma GCC diagnostic ignored "-Wnonnull"
#endif

  // Type-erased algorithm
  class TypeErasedAlgorithm {
    struct vtable {
      std::string (*name)(void const*) = nullptr;
      std::any (*create_ref_store)(
        const std::string&,
        std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>,
        std::vector<std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>>,
        Allen::Store::UnorderedStore&) = nullptr;
      void (*set_arguments_size)(void*, std::any&, const RuntimeOptions&, const Constants&) = nullptr;
      void (*invoke)(void const*, std::any&, const RuntimeOptions&, const Constants&, const Allen::Context&) = nullptr;
      void (*init)(void*) = nullptr;
      void (*set_properties)(void*, const std::map<std::string, nlohmann::json>&) = nullptr;
      std::map<std::string, nlohmann::json> (*get_properties)(void const*) = nullptr;
      std::string (*scope)() = nullptr;
      void (*dtor)(void*) = nullptr;
      void (*run_preconditions)(
        void* p,
        std::any& arg_ref_manager,
        const RuntimeOptions& runtime_options,
        const Constants& constants,
        const Allen::Context& context) = nullptr;
      void (*run_postconditions)(
        void* p,
        std::any& arg_ref_manager,
        const RuntimeOptions& runtime_options,
        const Constants& constants,
        const Allen::Context& context) = nullptr;
      void (*emplace_output_arguments)(const std::vector<std::string>& arguments, Allen::Store::UnorderedStore& store) =
        nullptr;
    };

    void* instance = nullptr;
    vtable table = {};

  public:
    template<typename ALGORITHM>
    TypeErasedAlgorithm(std::in_place_type_t<ALGORITHM>, const std::string& name)
    {
      auto p = new ALGORITHM {};
      p->set_name(name);
      instance = p;
      table = vtable {
        [](void const* p) { return static_cast<ALGORITHM const*>(p)->name(); },
        [](
          const std::string& name,
          std::vector<std::reference_wrapper<Allen::Store::BaseArgument>> vector_store_ref,
          std::vector<std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>> input_aggregates,
          Allen::Store::UnorderedStore& store) {
          using store_ref_t = typename AlgorithmTraits<ALGORITHM>::StoreRefType;
          using arguments_t = typename store_ref_t::arguments_t;
          using input_aggregates_t = typename store_ref_t::input_aggregates_t;
          if (std::tuple_size_v<arguments_t> != vector_store_ref.size()) {
            throw std::runtime_error(
              "algorithm " + name +
              " received an unexpected number of arguments: " + std::to_string(vector_store_ref.size()) +
              " were passed, while the store expects " + std::to_string(std::tuple_size_v<arguments_t>));
          }
          auto store_ref =
            create_store_ref(vector_store_ref, std::make_index_sequence<std::tuple_size_v<arguments_t>> {});
          auto input_agg_store = input_aggregates_t {Allen::Store::gen_input_aggregates_tuple(
            input_aggregates, std::make_index_sequence<std::tuple_size_v<input_aggregates_t>> {})};
          return std::any {store_ref_t {store_ref, input_agg_store, store}};
        },
        [](void* p, std::any& arg_ref_manager, const RuntimeOptions& runtime_options, const Constants& constants) {
          using store_ref_t = typename AlgorithmTraits<ALGORITHM>::StoreRefType;
          static_cast<ALGORITHM*>(p)->set_arguments_size(
            std::any_cast<store_ref_t&>(arg_ref_manager), runtime_options, constants);
        },
        [](
          const void* p,
          std::any& arg_ref_manager,
          const RuntimeOptions& runtime_options,
          const Constants& constants,
          const Allen::Context& context) {
          using store_ref_t = typename AlgorithmTraits<ALGORITHM>::StoreRefType;
          static_cast<ALGORITHM const*>(p)->operator()(
            std::any_cast<store_ref_t&>(arg_ref_manager), runtime_options, constants, context);
        },
        [](void* p) {
          if constexpr (Allen::has_init_member_fn<ALGORITHM>::value) {
            initialize_algorithm(*static_cast<ALGORITHM*>(p));
          }
          else {
            _unused(p);
          }
        },
        [](void* p, const std::map<std::string, nlohmann::json>& algo_config) {
          static_cast<ALGORITHM*>(p)->set_properties(algo_config);
        },
        [](void const* p) { return static_cast<ALGORITHM const*>(p)->get_properties(); },
        []() -> std::string { return ALGORITHM::algorithm_scope; },
        [](void* p) { delete static_cast<ALGORITHM*>(p); },
        [](
          void* p,
          std::any& arg_ref_manager,
          const RuntimeOptions& runtime_options,
          const Constants& constants,
          const Allen::Context& context) {
          using store_ref_t = typename AlgorithmTraits<ALGORITHM>::StoreRefType;
          using preconditions_t = typename AlgorithmContracts<typename ALGORITHM::contracts>::preconditions;
          if constexpr (std::tuple_size_v<preconditions_t>> 0) {
            auto preconditions = preconditions_t {};
            const auto location = static_cast<ALGORITHM const*>(p)->name();
            std::apply(
              [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
              preconditions);
            std::apply(
              [&](const auto&... contract) {
                (std::invoke(
                   contract, std::any_cast<store_ref_t&>(arg_ref_manager), runtime_options, constants, context),
                 ...);
              },
              preconditions);
          }
        },
        [](
          void* p,
          std::any& arg_ref_manager,
          const RuntimeOptions& runtime_options,
          const Constants& constants,
          const Allen::Context& context) {
          using store_ref_t = typename AlgorithmTraits<ALGORITHM>::StoreRefType;
          using postconditions_t = typename AlgorithmContracts<typename ALGORITHM::contracts>::postconditions;
          if constexpr (std::tuple_size_v<postconditions_t>> 0) {
            auto postconditions = postconditions_t {};
            const auto location = static_cast<ALGORITHM const*>(p)->name();
            std::apply(
              [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
              postconditions);
            std::apply(
              [&](const auto&... contract) {
                (std::invoke(
                   contract, std::any_cast<store_ref_t&>(arg_ref_manager), runtime_options, constants, context),
                 ...);
              },
              postconditions);
          }
        },
        [](const std::vector<std::string>& arguments, Allen::Store::UnorderedStore& store) {
          using parameters_tuple_t = typename AlgorithmTraits<ALGORITHM>::StoreRefType::parameters_tuple_t;
          ::emplace_output_argument<parameters_tuple_t>(
            arguments, store, std::make_index_sequence<std::tuple_size_v<parameters_tuple_t>> {});
        }};
    }
    ~TypeErasedAlgorithm() { (table.dtor)(instance); }
    TypeErasedAlgorithm(const TypeErasedAlgorithm&) = delete;
    TypeErasedAlgorithm(TypeErasedAlgorithm&& arg) : instance {std::exchange(arg.instance, nullptr)}, table {arg.table}
    {}
    TypeErasedAlgorithm& operator=(const TypeErasedAlgorithm&) = delete;
    TypeErasedAlgorithm& operator=(TypeErasedAlgorithm&&) = delete;

    std::string name() const { return (table.name)(instance); }
    std::any create_ref_store(
      std::vector<std::reference_wrapper<Allen::Store::BaseArgument>> vector_store_ref,
      std::vector<std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>> input_aggregates,
      Allen::Store::UnorderedStore& store)
    {
      return (table.create_ref_store)(name(), std::move(vector_store_ref), std::move(input_aggregates), store);
    }
    void
    set_arguments_size(std::any& arg_ref_manager, const RuntimeOptions& runtime_options, const Constants& constants)
    {
      (table.set_arguments_size)(instance, arg_ref_manager, runtime_options, constants);
    }
    void invoke(
      std::any& arg_ref_manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context)
    {
      (table.invoke)(instance, arg_ref_manager, runtime_options, constants, context);
    }
    void init() { (table.init)(instance); }
    void set_properties(const std::map<std::string, nlohmann::json>& algo_config)
    {
      (table.set_properties)(instance, algo_config);
    }
    std::map<std::string, nlohmann::json> get_properties() const { return (table.get_properties)(instance); }
    std::string scope() const { return (table.scope)(); }
    void run_preconditions(
      std::any& arg_ref_manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context)
    {
      return (table.run_preconditions)(instance, arg_ref_manager, runtime_options, constants, context);
    }
    void run_postconditions(
      std::any& arg_ref_manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context)
    {
      return (table.run_postconditions)(instance, arg_ref_manager, runtime_options, constants, context);
    }
    void emplace_output_arguments(const std::vector<std::string>& arguments, Allen::Store::UnorderedStore& store)
    {
      (table.emplace_output_arguments)(arguments, store);
    }
  };

#if __GNUC__ == 11
#pragma GCC diagnostic pop
#endif

  // Tool to instantiate algorithms
  template<typename T>
  TypeErasedAlgorithm instantiate_algorithm(const std::string& name);

#define INSTANTIATE_ALGORITHM(TYPE)                                                      \
  template<>                                                                             \
  Allen::TypeErasedAlgorithm Allen::instantiate_algorithm<TYPE>(const std::string& name) \
  {                                                                                      \
    return TypeErasedAlgorithm {std::in_place_type<TYPE>, name};                         \
  }

  // Forward declare to use in Algorithm
  template<typename V>
  class Property;

  /**
   * @brief      In addition to functionality in BaseAlgorithm, algorithms may need to access properties shared with
   * other algorithms
   *
   */
  struct Algorithm : BaseAlgorithm, ArgumentOperations {
    // Define empty contract container by default
    using contracts = std::tuple<>;

    template<typename T>
    using Property = Allen::Property<T>;

    Algorithm() = default;
    Algorithm(const Algorithm&) = delete;
    Algorithm& operator=(const Algorithm&) = delete;
    Algorithm(Algorithm&&) = delete;
    Algorithm& operator=(Algorithm&&) = delete;

    void set_properties(const std::map<std::string, nlohmann::json>& algo_config) override
    {
      for (auto kv : algo_config) {
        auto it = m_properties.find(kv.first);

        if (it == m_properties.end()) {
          std::cerr << "could not set " << kv.first << "=" << kv.second << "\n";
          const std::string error_message = "property " + kv.first + " does not exist";
          throw std::runtime_error {error_message};
        }
        else {
          try {
            it->second->from_json(kv.second);
          } catch (nlohmann::detail::type_error& e) {
            std::cerr << "json type error processing property " << kv.first << " of algorithm " << name() << "\n";
            throw e;
          }
        }
      }
    }

    template<typename T, typename R>
    void set_property_value(const R& value)
    {
      auto prop = const_cast<Allen::Property<T>*>(dynamic_cast<Allen::Property<T> const*>(get_prop(T::name)));
      prop->set_value(value);
    }

    // Gets the value of property with type T
    template<typename T>
    T property() const
    {
      const auto base_prop = get_prop(T::name);
      const auto prop = dynamic_cast<const Property<T>*>(base_prop);
      if (!prop) {
        const std::string error_message =
          "property " + std::string(T::name) + " not defined, perhaps member definition is missing";
        throw std::runtime_error {error_message};
      }
      return prop->get_value();
    }

    std::map<std::string, nlohmann::json> get_properties() const override
    {
      std::map<std::string, nlohmann::json> properties;
      for (const auto& kv : m_properties) {
        properties.emplace(kv.first, kv.second->to_json());
      }
      return properties;
    }

    bool register_property(std::string const& name, BaseProperty* property) override
    {
      auto r = m_properties.emplace(name, property);
      if (!std::get<1>(r)) {
        const std::string error_message = "could not register property " + name;
        throw std::runtime_error {error_message};
      }
      return std::get<1>(r);
    }

    // Setter and getter of name of the algorithm
    void set_name(const std::string& name) { m_name = name; }

    std::string name() const { return m_name; }

    template<typename Fn>
    auto host_function(const Fn& fn) const
    {
      return HostFunction<Fn> {m_properties, fn};
    }

    template<typename Fn>
    auto global_function(const Fn& fn) const
    {
      return GlobalFunction<Fn> {m_properties, fn};
    }

    template<typename... S>
    auto make_parameters(
      const dim3& grid_dim,
      const dim3& block_dim,
      const unsigned dynamic_shared_memory_size,
      S&&... arguments) const
    {
      return Allen::Gear::Function::make_parameters(
        m_properties, grid_dim, block_dim, dynamic_shared_memory_size, arguments...);
    }

    PROPERTY(verbosity_t, "verbosity", "verbosity of algorithm", int);

  protected:
    BaseProperty const* get_prop(const std::string& prop_name) const override
    {
      if (m_properties.find(prop_name) != m_properties.end()) {
        return m_properties.at(prop_name);
      }
      return nullptr;
    }

  private:
    std::map<std::string, BaseProperty*> m_properties;
    std::string m_name = "";
    Property<verbosity_t> m_verbosity = {this, 3};

#ifndef ALLEN_STANDALONE
  public:
    auto serviceLocator() { return m_serviceLocator; }

  private:
    StreamServiceLocator* m_serviceLocator = StreamServiceLocator::get();
#endif
  };
} // namespace Allen
