/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "MemoryManager.cuh"
#include "SchedulerMachinery.cuh"
#include "ArgumentManager.cuh"
#include "Logger.h"
#include <utility>
#include <type_traits>

// use constexpr flag to enable/disable contracts
#ifdef ENABLE_CONTRACTS
constexpr bool contracts_enabled = true;
#else
constexpr bool contracts_enabled = false;
#endif

#ifdef MEMORY_MANAGER_MULTI_ALLOC
using host_memory_manager_t = MemoryManager<memory_manager_details::Host, memory_manager_details::MultiAlloc>;
using device_memory_manager_t = MemoryManager<memory_manager_details::Device, memory_manager_details::MultiAlloc>;
#else
using host_memory_manager_t = MemoryManager<memory_manager_details::Host, memory_manager_details::SingleAlloc>;
using device_memory_manager_t = MemoryManager<memory_manager_details::Device, memory_manager_details::SingleAlloc>;
#endif

namespace details {

  template<auto I, typename Callable, typename... Tuples>
  constexpr auto invoke_at(Callable&& f, Tuples&&... tuples)
  {
    return std::invoke(f, std::get<I>(std::forward<Tuples>(tuples))...);
  }
  template<typename Callable, typename... Tuples, std::size_t... Is>
  constexpr void invoke_for_each_slice_impl(std::index_sequence<Is...>, Callable&& f, Tuples&&... tuples)
  {
    (invoke_at<Is>(std::forward<Callable>(f), std::forward<Tuples>(tuples)...), ...);
  }
  template<typename Callable, typename Tuple, typename... Tuples>
  constexpr void invoke_for_each_slice(Callable&& f, Tuple&& tuple, Tuples&&... tuples)
  {
    constexpr auto N = std::tuple_size_v<std::remove_reference_t<Tuple>>;
    static_assert(((N == std::tuple_size_v<std::remove_reference_t<Tuples>>) &&...));
    invoke_for_each_slice_impl(
      std::make_index_sequence<N> {},
      std::forward<Callable>(f),
      std::forward<Tuple>(tuple),
      std::forward<Tuples>(tuples)...);
  }

  template<typename SeqArgs, typename InDeps, typename OutDeps>
  struct Traits {
    using ConfiguredSequenceArgument = SeqArgs;
    using InputDependencies = InDeps;
    using OutputDependencies = OutDeps;
  };

  template<typename, typename, typename>
  struct TraitsList;

  template<typename... ConfiguredSequenceArgs, typename... InDeps, typename... OutDeps>
  struct TraitsList<std::tuple<ConfiguredSequenceArgs...>, std::tuple<InDeps...>, std::tuple<OutDeps...>> {
    static_assert(sizeof...(ConfiguredSequenceArgs) == sizeof...(InDeps));
    static_assert(sizeof...(InDeps) == sizeof...(OutDeps));
    using type = std::tuple<Traits<ConfiguredSequenceArgs, InDeps, OutDeps>...>;
  };

  template<typename ConfiguredSequenceArgs>
  using Traits_for = typename TraitsList<
    ConfiguredSequenceArgs,
    typename Sch::InDependencies<ConfiguredSequenceArgs>::t,
    typename Sch::OutDependencies<ConfiguredSequenceArgs>::t>::type;

} // namespace details

template<typename ConfiguredSequence, typename ConfiguredArguments, typename ConfiguredSequenceArguments>
class Scheduler {

  struct VTable {
    void* algorithm = nullptr;
    void (*configure)(void* self, const std::map<std::string, std::map<std::string, std::string>>& config) = nullptr;
    void (*get_configuration)(const void* self, std::map<std::string, std::map<std::string, std::string>>& config) =
      nullptr;
    std::string (*name)(const void* self) = nullptr;
    void (*run)(
      void* self,
      host_memory_manager_t&,
      device_memory_manager_t&,
      ArgumentManager<ConfiguredArguments>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context&,
      bool do_print) = nullptr;

    VTable() = default;

    template<typename Alg, typename Traits>
    VTable(Alg& alg, Traits) :
      algorithm {&alg}, configure {configure_<Alg>}, get_configuration {get_configuration_<Alg>},
      name {[](const void* self) { return static_cast<const Alg*>(self)->name(); }}, run {run_<Alg, Traits>}
    {}
  };

  // Configured sequence
  std::array<VTable, std::tuple_size_v<ConfiguredSequence>> vtbls;

  host_memory_manager_t host_memory_manager {"Host memory manager"};
  device_memory_manager_t device_memory_manager {"Device memory manager"};

  bool do_print = false;

  ConfiguredSequence sequence_tuple; // TODO: GR: replace with type-erased storage inside constructor;

public:
  ArgumentManager<ConfiguredArguments> argument_manager; // TOOD: GR: type erase me

  template<typename Names>
  constexpr Scheduler(Names&& names)
  {
    details::invoke_for_each_slice(
      [](auto& alg, auto&& name, auto traits, VTable& vtbl) {
        alg.set_name(std::forward<decltype(name)>(name));
        vtbl = VTable {alg, traits};
      },
      sequence_tuple,
      std::forward<Names>(names),
      details::Traits_for<ConfiguredSequenceArguments> {},
      vtbls);
  }
  Scheduler(const Scheduler&) = delete;
  Scheduler& operator=(const Scheduler&) = delete;
  Scheduler(Scheduler&&) = delete;
  Scheduler& operator=(Scheduler&&) = delete;

  void initialize(
    const bool param_do_print,
    const size_t device_requested_mb,
    const size_t host_requested_mb,
    const unsigned required_memory_alignment)
  {
    do_print = param_do_print;

    // Reserve memory in managers
    host_memory_manager.reserve_memory(host_requested_mb * 1000 * 1000, required_memory_alignment);
    device_memory_manager.reserve_memory(device_requested_mb * 1000 * 1000, required_memory_alignment);
  }

  /**
   * @brief Resets the memory manager.
   */
  void reset()
  {
    host_memory_manager.free_all();
    device_memory_manager.free_all();
  }

  // Configure constants for algorithms in the sequence
  void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config)
  {
    std::for_each(
      vtbls.begin(), vtbls.end(), [&config](auto& vtbl) { std::invoke(vtbl.configure, vtbl.algorithm, config); });
  }

  // Return constants for algorithms in the sequence
  auto get_algorithm_configuration()
  {
    std::map<std::string, std::map<std::string, std::string>> config;
    std::for_each(vtbls.begin(), vtbls.end(), [&config](auto& vtbl) {
      std::invoke(vtbl.get_configuration, vtbl.algorithm, config);
    });
    return config;
  }

  //  Runs a sequence of algorithms.
  void run(
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers* host_buffers,
    const Allen::Context& context)
  {
    std::for_each(vtbls.begin(), vtbls.end(), [&](auto& vtbl) {
      std::invoke(
        vtbl.run,
        vtbl.algorithm,
        host_memory_manager,
        device_memory_manager,
        argument_manager,
        runtime_options,
        constants,
        *host_buffers,
        context,
        do_print);
    });
  }

private:
  template<typename Alg>
  static void configure_(void* self, const std::map<std::string, std::map<std::string, std::string>>& config)
  {
    auto* algorithm = static_cast<Alg*>(self);
    auto c = config.find(algorithm->name());
    if (c != config.end()) algorithm->set_properties(c->second);
    // * Invoke void initialize() const, iff it exists
    if constexpr (has_member_fn<Alg>::value) {
      algorithm->init();
    };
  }

  template<typename Alg>
  static void get_configuration_(const void* self, std::map<std::string, std::map<std::string, std::string>>& config)
  {
    auto* algorithm = static_cast<const Alg*>(self);
    config.emplace(algorithm->name(), algorithm->get_properties());
  }

  template<typename out_arguments_t, typename in_arguments_t, typename Alg, typename argument_manager_t>
  static void setup_(
    Alg* algorithm,
    host_memory_manager_t& host_memory_manager,
    device_memory_manager_t& device_memory_manager,
    argument_manager_t& argument_manager,
    bool do_print)
  {
    /**
     * @brief Runs a step of the scheduler and determines
     *        the offset for each argument.
     *
     *        The sequence is asserted at compile time to run the
     *        expected iteration and reserve the expected types.
     *
     *        This function should always be invoked, even when it is
     *        known there are no tags to reserve or free on this step.
     */
    if (do_print) {
      info_cout << "Sequence step \"" << algorithm->name() << "\":\n";
    }

    // Free all arguments in OutDependencies
    MemoryManagerFree<host_memory_manager_t, device_memory_manager_t, argument_manager_t, out_arguments_t>::free(
      host_memory_manager, device_memory_manager, argument_manager);

    // Reserve all arguments in InDependencies
    MemoryManagerReserve<host_memory_manager_t, device_memory_manager_t, argument_manager_t, in_arguments_t>::reserve(
      host_memory_manager, device_memory_manager, argument_manager);

    // Print memory manager state
    if (do_print) {
      host_memory_manager.print();
      device_memory_manager.print();
    }
  }

  template<typename Alg, typename Traits>
  static void run_(
    void* self,
    host_memory_manager_t& host_memory_manager,
    device_memory_manager_t& device_memory_manager,
    ArgumentManager<ConfiguredArguments>& argument_manager,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    const Allen::Context& context,
    bool do_print)
  {
    using configured_arguments_t = typename Traits::ConfiguredSequenceArgument;
    // in dependencies: Dependencies to be reserved
    using in_arguments_t = typename Traits::InputDependencies;
    // out dependencies: Dependencies to be free'd
    using out_arguments_t = typename Traits::OutputDependencies;
    auto* algorithm = static_cast<Alg*>(self);
    auto arguments_tuple = Sch::ProduceArgumentsTuple<ConfiguredArguments, Alg, configured_arguments_t>::produce(
      argument_manager.argument_database());

    // Get pre and postconditions -- conditional on `contracts_enabled`
    // Starting at -O1, gcc will entirely remove the contracts code when not enabled, see
    // https://godbolt.org/z/67jxx7
    using algorithm_contracts = Sch::AlgorithmContracts<typename Alg::contracts>;
    auto preconditions =
      std::conditional_t<contracts_enabled, typename algorithm_contracts::preconditions, std::tuple<>> {};
    auto postconditions =
      std::conditional_t<contracts_enabled, typename algorithm_contracts::postconditions, std::tuple<>> {};

    // Set location
    const auto location = algorithm->name();
    std::apply(
      [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
      preconditions);
    std::apply(
      [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
      postconditions);

    // Sets the arguments sizes
    algorithm->set_arguments_size(arguments_tuple, runtime_options, constants, host_buffers);

    // Setup algorithm, reserving / freeing memory buffers
    setup_<out_arguments_t, in_arguments_t>(
      algorithm, host_memory_manager, device_memory_manager, argument_manager, do_print);

    // Run preconditions
    std::apply(
      [&](const auto&... contract) {
        (std::invoke(contract, arguments_tuple, runtime_options, constants, context), ...);
      },
      preconditions);

    try {
      // Invoke the algorithm
      std::invoke(*algorithm, arguments_tuple, runtime_options, constants, host_buffers, context);
    } catch (std::invalid_argument& e) {
      fprintf(stderr, "Execution of algorithm %s raised an exception\n", algorithm->name().c_str());
      throw e;
    }

    // Run postconditions
    std::apply(
      [&](const auto&... contract) {
        (std::invoke(contract, arguments_tuple, runtime_options, constants, context), ...);
      },
      postconditions);
  }
};
