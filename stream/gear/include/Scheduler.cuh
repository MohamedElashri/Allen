/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "MemoryManager.cuh"
#include "ArgumentManager.cuh"
#include "Configuration.cuh"
#include "Logger.h"
#include <utility>
#include <type_traits>
#include <AlgorithmDB.h>

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

class Scheduler {
  std::vector<Allen::TypeErasedAlgorithm> m_sequence;
  UnorderedStore m_store;
  std::vector<std::any> m_sequence_argument_ref_managers;
  std::vector<LifetimeDependencies> m_in_dependencies;
  std::vector<LifetimeDependencies> m_out_dependencies;
  host_memory_manager_t host_memory_manager {"Host memory manager"};
  device_memory_manager_t device_memory_manager {"Device memory manager"};
  bool do_print = false;

public:
  Scheduler(const ConfiguredSequence& configuration,
    const bool param_do_print,
    const size_t device_requested_mb,
    const size_t host_requested_mb,
    const unsigned required_memory_alignment)
  {
    auto& [configured_algorithms, configured_arguments, sequence_arguments, arg_deps] = configuration;
    assert(configured_algorithms.size() == sequence_arguments.size());

    // Generate type erased sequence
    instantiate_sequence(configured_algorithms);

    // Create and populate store
    initialize_store(configured_arguments);

    // Calculate in and out dependencies of defined sequence
    std::tie(m_in_dependencies, m_out_dependencies) = calculate_lifetime_dependencies(sequence_arguments, arg_deps);

    // Create ArgumentRefManager of each algorithm
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      // Generate store references for each algorithm's configured arguments
      auto [alg_store_ref, alg_input_aggregates] = generate_algorithm_store_ref(sequence_arguments[i]);
      m_sequence_argument_ref_managers.emplace_back(m_sequence[i].create_arg_ref_manager(alg_store_ref, alg_input_aggregates));
    }

    assert(configured_algorithms.size() == m_sequence.size());
    assert(configured_algorithms.size() == m_sequence_argument_ref_managers.size());
    assert(configured_algorithms.size() == m_in_dependencies.size());
    assert(configured_algorithms.size() == m_out_dependencies.size());

    do_print = param_do_print;

    // Reserve memory in managers
    host_memory_manager.reserve_memory(host_requested_mb * 1000 * 1000, required_memory_alignment);
    device_memory_manager.reserve_memory(device_requested_mb * 1000 * 1000, required_memory_alignment);
  }
  
  Scheduler(const Scheduler&) = delete;
  Scheduler& operator=(const Scheduler&) = delete;
  Scheduler(Scheduler&&) = delete;
  Scheduler& operator=(Scheduler&&) = delete;

  /**
   * @brief Instantiates all algorithms in the configured sequence
   */
  void instantiate_sequence(const std::vector<ConfiguredAlgorithm>& configured_algorithms) {
    for (const auto& alg : configured_algorithms) {
      m_sequence.emplace_back(instantiate_allen_algorithm(alg));
    }
  }

  /**
   * @brief Initializes the store with the configured arguments
   */
  void initialize_store(const std::vector<ConfiguredArgument>& configured_arguments) {
    for (const auto& arg : configured_arguments) {
      m_store.emplace(arg.name, create_allen_argument(arg));
    }
  }

  /**
   * @brief Generate the store ref of an algorithm
   */
  std::tuple<std::vector<std::reference_wrapper<ArgumentData>>, std::vector<std::vector<std::reference_wrapper<ArgumentData>>>> generate_algorithm_store_ref(
    const ConfiguredAlgorithmArguments& configured_alg_arguments) {
    std::vector<std::reference_wrapper<ArgumentData>> store_ref;
    std::vector<std::vector<std::reference_wrapper<ArgumentData>>> input_aggregates;

    for (const auto& argument : configured_alg_arguments.arguments) {
      store_ref.push_back(m_store.at(argument));
    }

    for (const auto& conf_input_aggregate : configured_alg_arguments.input_aggregates) {
      std::vector<std::reference_wrapper<ArgumentData>> input_aggregate;
      for (const auto& argument : conf_input_aggregate) {
        input_aggregate.push_back(m_store.at(argument));
      }
      input_aggregates.emplace_back(input_aggregate);
    }

    return {store_ref, input_aggregates};
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
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      configure(m_sequence[i], config);
    }
  }

  // Return constants for algorithms in the sequence
  auto get_algorithm_configuration() const
  {
    std::map<std::string, std::map<std::string, std::string>> config;
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      get_configuration(m_sequence[i], config);
    }
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
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      run(m_sequence[i],
        m_sequence_argument_ref_managers[i],
        m_in_dependencies[i],
        m_out_dependencies[i],
        host_memory_manager,
        device_memory_manager,
        m_store,
        runtime_options,
        constants,
        *host_buffers,
        context,
        do_print);
    }
  }

private:
  static void configure(Allen::TypeErasedAlgorithm& algorithm, const std::map<std::string, std::map<std::string, std::string>>& config)
  {
    auto c = config.find(algorithm.name(algorithm.instance));
    if (c != config.end()) algorithm.set_properties(algorithm.instance, c->second);
    // * Invoke void initialize() const, iff it exists
    algorithm.init(algorithm.instance);
  }

  static void get_configuration(const Allen::TypeErasedAlgorithm&, std::map<std::string, std::map<std::string, std::string>>&)
  {
    // TODO: get_properties is currently segfaulting
    // config.emplace(algorithm.name(algorithm.instance), algorithm.get_properties(algorithm.instance));
  }

  static void setup(
    Allen::TypeErasedAlgorithm& algorithm,
    const LifetimeDependencies& in_dependencies,
    const LifetimeDependencies& out_dependencies,
    host_memory_manager_t& host_memory_manager,
    device_memory_manager_t& device_memory_manager,
    UnorderedStore& store,
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
      info_cout << "Sequence step \"" << algorithm.name(algorithm.instance) << "\":\n";
    }

    // Free all arguments in OutDependencies
    MemoryManagerHelper::free(host_memory_manager, device_memory_manager, store, out_dependencies);

    // Reserve all arguments in InDependencies
    MemoryManagerHelper::reserve(host_memory_manager, device_memory_manager, store, in_dependencies);

    // Print memory manager state
    if (do_print) {
      host_memory_manager.print();
      device_memory_manager.print();
    }
  }

  static void run(
    Allen::TypeErasedAlgorithm& algorithm,
    std::any& argument_ref_manager,
    const LifetimeDependencies& in_dependencies,
    const LifetimeDependencies& out_dependencies,
    host_memory_manager_t& host_memory_manager,
    device_memory_manager_t& device_memory_manager,
    UnorderedStore& store,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    const Allen::Context& context,
    bool do_print)
  {
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
    algorithm.set_arguments_size(
      algorithm.instance, argument_ref_manager, runtime_options, constants, host_buffers);

    // Setup algorithm, reserving / freeing memory buffers
    setup(
      algorithm, in_dependencies, out_dependencies, host_memory_manager, device_memory_manager, store, do_print);

    // // Run preconditions
    // std::apply(
    //   [&](const auto&... contract) {
    //     (std::invoke(contract, arguments_tuple, runtime_options, constants, context), ...);
    //   },
    //   preconditions);

    try {
      // Invoke the algorithm
      algorithm.invoke(algorithm.instance, argument_ref_manager, runtime_options, constants, host_buffers, context);
    } catch (std::invalid_argument& e) {
      fprintf(stderr, "Execution of algorithm %s raised an exception\n", algorithm.name(algorithm.instance).c_str());
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
