/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Store.cuh"
#include "Configuration.cuh"
#include "Logger.h"
#include <utility>
#include <type_traits>
#include <AlgorithmDB.h>
#include "nlohmann/json.hpp"

// use constexpr flag to enable/disable contracts
#ifdef ENABLE_CONTRACTS
constexpr bool contracts_enabled = true;
#else
constexpr bool contracts_enabled = false;
#endif

class Scheduler {
  std::vector<Allen::TypeErasedAlgorithm> m_sequence;
  Allen::Store::UnorderedStore m_store;
  std::vector<std::any> m_sequence_ref_stores;
  std::vector<LifetimeDependencies> m_in_dependencies;
  std::vector<LifetimeDependencies> m_out_dependencies;
  bool do_print = false;

private:
  // Get in and out dependencies
  std::tuple<std::vector<LifetimeDependencies>, std::vector<LifetimeDependencies>> calculate_lifetime_dependencies(
    const std::vector<ConfiguredAlgorithmArguments>& sequence_arguments,
    const ArgumentDependencies& argument_dependencies,
    const std::vector<Allen::TypeErasedAlgorithm>& sequence)
  {
    std::vector<LifetimeDependencies> in_deps;
    std::vector<LifetimeDependencies> out_deps;
    std::vector<std::string> temp_arguments;

    const auto argument_in = [](const std::string& arg, const auto& args) {
      return std::find(std::begin(args), std::end(args), arg) != std::end(args);
    };

    const auto argument_in_map = [](const std::string& arg, const auto& args) {
      return args.find(arg) != std::end(args);
    };

    auto seq_args = sequence_arguments;

    // Add all dependencies from all SelectionAlgorithms to in_deps of algorithm gather_selections
    std::set<std::string> selection_arguments;
    for (unsigned i = 0; i < seq_args.size(); ++i) {
      if (sequence[i].scope() == "SelectionAlgorithm") {
        for (const auto& arg : seq_args[i].arguments) {
          selection_arguments.insert(arg);
        }
      }
      if (sequence[i].name() == "gather_selections") {
        for (const auto& arg : selection_arguments) {
          seq_args[i].arguments.push_back(arg);
        }
      }
    }

    for (unsigned i = 0; i < seq_args.size(); ++i) {
      // Calculate out_dep for this algorithm
      LifetimeDependencies out_dep;
      std::vector<std::string> next_temp_arguments;

      for (const auto& arg : temp_arguments) {
        bool arg_can_be_freed = true;

        for (unsigned j = i; j < seq_args.size(); ++j) {
          const auto& alg = seq_args[j];
          if (argument_in(arg, alg.arguments)) {
            arg_can_be_freed = false;
          }

          // dependencies
          for (const auto& alg_arg : alg.arguments) {
            if (
              argument_in_map(alg_arg, argument_dependencies) && argument_in(arg, argument_dependencies.at(alg_arg))) {
              arg_can_be_freed = false;
              break;
            }
          }

          // input aggregates
          for (const auto& input_aggregate : alg.input_aggregates) {
            if (argument_in(arg, input_aggregate)) {
              arg_can_be_freed = false;
              break;
            }
          }

          if (!arg_can_be_freed) {
            break;
          }
        }

        if (arg_can_be_freed) {
          out_dep.arguments.push_back(arg);
        }
        else {
          next_temp_arguments.push_back(arg);
        }
      }
      out_deps.emplace_back(out_dep);

      // Update temp_arguments
      temp_arguments = next_temp_arguments;

      // Calculate in_dep for this algorithm
      LifetimeDependencies in_dep;
      for (const auto& arg : seq_args[i].arguments) {
        if (!argument_in(arg, temp_arguments)) {
          temp_arguments.push_back(arg);
          in_dep.arguments.push_back(arg);
        }
      }
      in_deps.emplace_back(in_dep);
    }

    return {in_deps, out_deps};
  }

public:
  Scheduler(
    const ConfiguredSequence& configuration,
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
    initialize_store(configured_arguments, sequence_arguments);

    // Calculate in and out dependencies of defined sequence
    std::tie(m_in_dependencies, m_out_dependencies) =
      calculate_lifetime_dependencies(sequence_arguments, arg_deps, m_sequence);

    // Create ArgumentRefManager of each algorithm
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      // Generate store references for each algorithm's configured arguments
      auto [alg_arguments, alg_input_aggregates] = generate_algorithm_store_ref(sequence_arguments[i]);
      m_sequence_ref_stores.emplace_back(m_sequence[i].create_ref_store(alg_arguments, alg_input_aggregates, m_store));
    }

    assert(configured_algorithms.size() == m_sequence.size());
    assert(configured_algorithms.size() == m_sequence_ref_stores.size());
    assert(configured_algorithms.size() == m_in_dependencies.size());
    assert(configured_algorithms.size() == m_out_dependencies.size());

    do_print = param_do_print;

    // Reserve memory in managers
    m_store.reserve_memory_host(host_requested_mb, required_memory_alignment);
    m_store.reserve_memory_device(device_requested_mb, required_memory_alignment);
  }

  Scheduler(const Scheduler&) = delete;
  Scheduler& operator=(const Scheduler&) = delete;
  Scheduler(Scheduler&&) = delete;
  Scheduler& operator=(Scheduler&&) = delete;

  /**
   * @brief Instantiates all algorithms in the configured sequence
   */
  void instantiate_sequence(const std::vector<ConfiguredAlgorithm>& configured_algorithms)
  {
    // Reserve the size of the sequence to avoid calls to the copy constructor when emplacing to this vector
    m_sequence.reserve(configured_algorithms.size());
    for (const auto& alg : configured_algorithms) {
      m_sequence.emplace_back(instantiate_allen_algorithm(alg));
    }
  }

  /**
   * @brief Initializes the store with the configured arguments
   */
  void initialize_store(
    const std::vector<ConfiguredArgument>&,
    const std::vector<ConfiguredAlgorithmArguments>& configured_algorithm_arguments)
  {
    assert(m_sequence.size() == configured_algorithm_arguments.size());
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      m_sequence[i].emplace_output_arguments(configured_algorithm_arguments[i].arguments, m_store);
    }
  }

  /**
   * @brief Generate the store ref of an algorithm
   */
  std::tuple<
    std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>,
    std::vector<std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>>>
  generate_algorithm_store_ref(const ConfiguredAlgorithmArguments& configured_alg_arguments)
  {
    std::vector<std::reference_wrapper<Allen::Store::BaseArgument>> store_ref;
    std::vector<std::vector<std::reference_wrapper<Allen::Store::BaseArgument>>> input_aggregates;

    for (const auto& argument : configured_alg_arguments.arguments) {
      store_ref.push_back(m_store.at(argument));
    }

    for (const auto& conf_input_aggregate : configured_alg_arguments.input_aggregates) {
      std::vector<std::reference_wrapper<Allen::Store::BaseArgument>> input_aggregate;
      for (const auto& argument : conf_input_aggregate) {
        input_aggregate.push_back(m_store.at(argument));
      }
      input_aggregates.emplace_back(input_aggregate);
    }

    return {store_ref, input_aggregates};
  }

  /**
   * @brief Free the memory managers.
   */
  void free_all() { m_store.free_all(); }

  // Configure constants for algorithms in the sequence
  void configure_algorithms(const std::map<std::string, std::map<std::string, nlohmann::json>>& config)
  {
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      configure(m_sequence[i], config);
    }
  }

  // Return constants for algorithms in the sequence
  auto get_algorithm_configuration() const
  {
    std::map<std::string, std::map<std::string, nlohmann::json>> config;
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      get_configuration(m_sequence[i], config);
    }
    return config;
  }

  void print_sequence() const
  {
    info_cout << "\nSequence:\n";
    for (const auto& alg : m_sequence) {
      info_cout << "  " << alg.name() << "\n";
    }
    info_cout << "\n";
  }

  bool contains_validation_algorithms() const
  {
    for (const auto& alg : m_sequence) {
      if (alg.scope() == "ValidationAlgorithm") {
        return true;
      }
    }
    return false;
  }

  //  Runs a sequence of algorithms.
  void run(
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& persistent_buffers,
    const Allen::Context& context)
  {
    for (unsigned i = 0; i < m_sequence.size(); ++i) {
      run(
        m_sequence[i],
        m_sequence_ref_stores[i],
        m_in_dependencies[i],
        m_out_dependencies[i],
        m_store,
        runtime_options,
        constants,
        persistent_buffers,
        context,
        do_print);
    }
  }

private:
  static void configure(
    Allen::TypeErasedAlgorithm& algorithm,
    const std::map<std::string, std::map<std::string, nlohmann::json>>& config)
  {
    auto c = config.find(algorithm.name());
    if (c != config.end()) algorithm.set_properties(c->second);
    // * Invoke void initialize() const, iff it exists
    algorithm.init();
  }

  static void get_configuration(
    const Allen::TypeErasedAlgorithm& algorithm,
    std::map<std::string, std::map<std::string, nlohmann::json>>& config)
  {
    config.emplace(algorithm.name(), algorithm.get_properties());
  }

  static void setup(
    Allen::TypeErasedAlgorithm& algorithm,
    const LifetimeDependencies& in_dependencies,
    const LifetimeDependencies& out_dependencies,
    Allen::Store::UnorderedStore& store,
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
      info_cout << "Sequence step \"" << algorithm.name() << "\":\n";
    }

    // Free arguments in OutDependencies
    for (const auto& arg : out_dependencies.arguments) {
      store.free(arg);
    }

    // Reserve all arguments in InDependencies
    for (const auto& arg : in_dependencies.arguments) {
      store.put(arg);
    }

    // Print memory manager state
    if (do_print) {
      store.print_memory_manager_states();
    }
  }

  static void run(
    Allen::TypeErasedAlgorithm& algorithm,
    std::any& argument_ref_manager,
    const LifetimeDependencies& in_dependencies,
    const LifetimeDependencies& out_dependencies,
    Allen::Store::UnorderedStore& store,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& persistent_buffers,
    const Allen::Context& context,
    bool do_print)
  {
    // Sets the arguments sizes
    algorithm.set_arguments_size(argument_ref_manager, runtime_options, constants, persistent_buffers);

    // Setup algorithm, reserving / freeing memory buffers
    setup(algorithm, in_dependencies, out_dependencies, store, do_print);

    // Run preconditions
    if constexpr (contracts_enabled) {
      algorithm.run_preconditions(argument_ref_manager, runtime_options, constants, context);
    }

    try {
      // Invoke the algorithm
      algorithm.invoke(argument_ref_manager, runtime_options, constants, persistent_buffers, context);
    } catch (std::invalid_argument& e) {
      fprintf(stderr, "Execution of algorithm %s raised an exception\n", algorithm.name().c_str());
      throw e;
    }

    // Store persistent buffers
    // store_persistent_buffers(persistent_buffers);

    // Run postconditions
    if constexpr (contracts_enabled) {
      algorithm.run_postconditions(argument_ref_manager, runtime_options, constants, context);
    }
  }
};
