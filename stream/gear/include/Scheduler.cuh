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

  template<auto I, typename Callable, typename Sequence, typename... Tuples>
  constexpr auto invoke_row_at(Callable&& f, Sequence&& sequence, Tuples&&... tuples)
  {
    return std::invoke(std::forward<Callable>(f), sequence[I], std::get<I>(std::forward<Tuples>(tuples))...);
  }

  template<typename Callable, typename Sequence, typename... Tuples, std::size_t... Is>
  constexpr void
  invoke_for_each_row_impl(std::index_sequence<Is...>, Sequence&& sequence, Callable&& f, Tuples&&... tuples)
  {
    (invoke_row_at<Is>(f, sequence, std::forward<Tuples>(tuples)...), ...);
  }

  /*
   * loop over each 'row' (aka slice) of the provided N tuples, and for each row,
   * invoke an N-ary callable on the thus-obtained N arguments
   * or to put it another way: 'zip tuples, followed by for_each'
   */
  template<typename Callable, typename Sequence, typename Tuple, typename... Tuples>
  constexpr void invoke_for_each_row(Callable&& f, Sequence&& sequence, Tuple&& tuple, Tuples&&... tuples)
  {
    constexpr auto N = std::tuple_size_v<std::remove_reference_t<Tuple>>;
    static_assert(((N == std::tuple_size_v<std::remove_reference_t<Tuples>>) &&...));
    invoke_for_each_row_impl(
      std::make_index_sequence<N> {},
      std::forward<Sequence>(sequence),
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

  template<typename ConfiguredSequenceArgs, typename InDeps, typename OutDeps>
  using Traits_for = typename TraitsList<ConfiguredSequenceArgs, InDeps, OutDeps>::type;

} // namespace details

template<
  size_t N,
  typename ConfiguredArguments,
  typename ConfiguredSequenceArguments,
  typename InDeps,
  typename OutDeps,
  typename TypeErasedSequence>
class Scheduler {

  struct VTable {
    Allen::TypeErasedAlgorithm* algorithm = nullptr;
    void (*configure)(void* self, const std::map<std::string, std::map<std::string, std::string>>& config) = nullptr;
    void (*get_configuration)(const void* self, std::map<std::string, std::map<std::string, std::string>>& config) =
      nullptr;
    std::function<std::string()> name = nullptr;
    std::string (*type)() = nullptr;
    void (*run)(
      Allen::TypeErasedAlgorithm* self,
      host_memory_manager_t&,
      device_memory_manager_t&,
      ArgumentManager<ConfiguredArguments>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context&,
      bool do_print) = nullptr;

    VTable() = default;

    template<typename Traits>
    VTable(Allen::TypeErasedAlgorithm& alg, Traits) :
      algorithm {&alg},
      // configure {configure_<Allen::TypeErasedAlgorithm>},
      // get_configuration {get_configuration_<Allen::TypeErasedAlgorithm>},
      // type {[] { return demangle<Allen::TypeErasedAlgorithm>(); }},
      run {run_<Traits>}, name {[this]() { return this->algorithm->name(this->algorithm->instance); }}
    {}
  };

  std::array<VTable, N> vtbls;
  host_memory_manager_t host_memory_manager {"Host memory manager"};
  device_memory_manager_t device_memory_manager {"Device memory manager"};
  TypeErasedSequence m_type_erased_sequence;

  bool do_print = false;

public:
  ArgumentManager<ConfiguredArguments> argument_manager; // TOOD: GR: type erase me

  constexpr Scheduler(TypeErasedSequence type_erased_sequence) : m_type_erased_sequence(type_erased_sequence)
  {
    details::invoke_for_each_row(
      [](auto& alg, auto traits, VTable& vtbl) {
        vtbl = VTable {alg, traits};
      },
      m_type_erased_sequence,
      details::Traits_for<ConfiguredSequenceArguments, InDeps, OutDeps> {},
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
    std::for_each(vtbls.begin(), vtbls.end(), [&config](auto& vtbl) {
      // std::invoke(vtbl.configure, vtbl.algorithm, config);
    });
  }

  // Return constants for algorithms in the sequence
  auto get_algorithm_configuration() const
  {
    std::map<std::string, std::map<std::string, std::string>> config;
    std::for_each(vtbls.begin(), vtbls.end(), [&config](auto& vtbl) {
      // std::invoke(vtbl.get_configuration, vtbl.algorithm, config);
    });
    return config;
  }

  void print_sequence() const
  {
    // info_cout << "\nSequence:\n";
    // std::for_each(vtbls.begin(), vtbls.end(), [](auto& vtbl) {
    //   auto t = vtbl.type();
    //   auto n = t.find("::");
    //   if (n != std::string::npos) {
    //     t = t.substr(n + 2);
    //   }
    //   info_cout << t << "/" << vtbl.name(vtbl.algorithm) << "\n";
    // });
    // info_cout << "\n";
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
  // template<typename Alg>
  // static void configure_(void* self, const std::map<std::string, std::map<std::string, std::string>>& config)
  // {
  //   auto* algorithm = static_cast<Alg*>(self);
  //   auto c = config.find(algorithm->name());
  //   if (c != config.end()) algorithm->set_properties(c->second);
  //   // * Invoke void initialize() const, iff it exists
  //   if constexpr (Allen::has_init_member_fn<Alg>::value) {
  //     algorithm->init();
  //   };
  // }

  // template<typename Alg>
  // static void get_configuration_(const void* self, std::map<std::string, std::map<std::string, std::string>>& config)
  // {
  //   auto* algorithm = static_cast<const Alg*>(self);
  //   config.emplace(algorithm->name(), algorithm->get_properties());
  // }

  template<typename out_arguments_t, typename in_arguments_t, typename argument_manager_t>
  static void setup_(
    Allen::TypeErasedAlgorithm* algorithm,
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
      info_cout << "Sequence step \"" << algorithm->name(algorithm->instance) << "\":\n";
    }

    // Free all arguments in OutDependencies
    MemoryManagerHelper<out_arguments_t>::free(host_memory_manager, device_memory_manager, argument_manager);

    // Reserve all arguments in InDependencies
    MemoryManagerHelper<in_arguments_t>::reserve(host_memory_manager, device_memory_manager, argument_manager);

    // Print memory manager state
    if (do_print) {
      host_memory_manager.print();
      device_memory_manager.print();
    }
  }

  template<typename Traits>
  static void run_(
    Allen::TypeErasedAlgorithm* algorithm,
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

    auto arguments_tuple = Sch::ProduceArgumentsTuple<ConfiguredArguments, configured_arguments_t>::produce(
      argument_manager.argument_database());

    // // Get pre and postconditions -- conditional on `contracts_enabled`
    // // Starting at -O1, gcc will entirely remove the contracts code when not enabled, see
    // // https://godbolt.org/z/67jxx7
    // using algorithm_contracts = Sch::AlgorithmContracts<typename Alg::contracts>;
    // auto preconditions =
    //   std::conditional_t<contracts_enabled, typename algorithm_contracts::preconditions, std::tuple<>> {};
    // auto postconditions =
    //   std::conditional_t<contracts_enabled, typename algorithm_contracts::postconditions, std::tuple<>> {};

    // // Set location
    // const auto location = algorithm->name();
    // std::apply(
    //   [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
    //   preconditions);
    // std::apply(
    //   [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
    //   postconditions);

    // Sets the arguments sizes
    algorithm->set_arguments_size(
      algorithm->instance, arguments_tuple.first, arguments_tuple.second, runtime_options, constants, host_buffers);

    // Setup algorithm, reserving / freeing memory buffers
    setup_<out_arguments_t, in_arguments_t>(
      algorithm, host_memory_manager, device_memory_manager, argument_manager, do_print);

    // // Run preconditions
    // std::apply(
    //   [&](const auto&... contract) {
    //     (std::invoke(contract, arguments_tuple, runtime_options, constants, context), ...);
    //   },
    //   preconditions);

    try {
      // Invoke the algorithm
      algorithm->invoke(algorithm->instance, arguments_tuple.first, arguments_tuple.second, runtime_options, constants, host_buffers, context);
    } catch (std::invalid_argument& e) {
      fprintf(stderr, "Execution of algorithm %s raised an exception\n", algorithm->name(algorithm->instance).c_str());
      throw e;
    }

    // // Run postconditions
    // std::apply(
    //   [&](const auto&... contract) {
    //     (std::invoke(contract, arguments_tuple, runtime_options, constants, context), ...);
    //   },
    //   postconditions);
  }
};

template<
  typename configured_arguments_t,
  typename configured_sequence_arguments_t,
  typename in_deps_t,
  typename out_deps_t,
  typename type_erased_sequence_t>
using SchedulerFor_t = Scheduler<
  std::tuple_size_v<configured_sequence_arguments_t>,
  configured_arguments_t,
  configured_sequence_arguments_t,
  in_deps_t,
  out_deps_t,
  type_erased_sequence_t>;
