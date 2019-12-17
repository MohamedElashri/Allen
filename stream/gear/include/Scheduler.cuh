#pragma once

#include "MemoryManager.cuh"
#include "SchedulerMachinery.cuh"
#include "ArgumentManager.cuh"
#include "Logger.h"
#include <utility>

template<typename ConfiguredSequence, typename OutputArguments>
struct Scheduler {
  // Dependencies calculated at compile time
  // Determines what to free (out_deps) and reserve (in_deps)
  // at every iteration.
  using in_deps_t = typename Sch::InDependencies<ConfiguredSequence>::t;
  using out_deps_t = typename Sch::OutDependencies<ConfiguredSequence, OutputArguments>::t;
  using arguments_tuple_t = typename Sch::ArgumentsTuple<in_deps_t>::t;
  using argument_manager_t = ArgumentManager<arguments_tuple_t>;

  MemoryManager device_memory_manager;
  MemoryManager host_memory_manager;
  argument_manager_t argument_manager;
  bool do_print = false;

  // Configured sequence
  ConfiguredSequence sequence_tuple;

  Scheduler() = default;
  Scheduler(const Scheduler&) = delete;

  void initialize(
    const bool param_do_print,
    const size_t device_reserved_mb,
    char* device_base_pointer,
    const size_t host_reserved_mb,
    char* host_base_pointer)
  {
    do_print = param_do_print;

    // Set max mb to memory_manager
    device_memory_manager.set_reserved_memory(device_reserved_mb);
    host_memory_manager.set_reserved_memory(host_reserved_mb);
    argument_manager.set_base_pointers(device_base_pointer, host_base_pointer);

    if (logger::ll.verbosityLevel >= logger::verbose) {
      // TODO
      // verbose_cout << "All arguments:" << std::endl << "[" << std::endl;
      // Sch::PrintAlgorithmSequenceDetailed<ConfiguredSequence>::print();
      // verbose_cout << "]\n\n";

      // verbose_cout << "IN deps:" << std::endl << "[" << std::endl;
      // Sch::PrintAlgorithmDependencies<in_deps_t>::print();
      // verbose_cout << "]\n\n";

      // verbose_cout << "OUT deps:" << std::endl << "[" << std::endl;
      // Sch::PrintAlgorithmDependencies<out_deps_t>::print();
      // verbose_cout << "]\n\n";
    }
  }

  /**
   * @brief Resets the memory manager.
   */
  void reset() {
    device_memory_manager.free_all();
    host_memory_manager.free_all();
  }

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
  template<unsigned long I, typename T>
  void setup()
  {
    // in dependencies: Dependencies to be reserved
    // out dependencies: Dependencies to be free'd
    //
    // in_deps and out_deps should be in order
    // and index I should contain algorithm type T
    using in_deps_I_t = typename std::tuple_element<I, in_deps_t>::type;
    using out_deps_I_t = typename std::tuple_element<I, out_deps_t>::type;
    using in_algorithm = typename in_deps_I_t::Algorithm;
    using in_arguments = typename in_deps_I_t::Arguments;
    using out_algorithm = typename out_deps_I_t::Algorithm;
    using out_arguments = typename out_deps_I_t::Arguments;

    static_assert(std::is_same<T, in_algorithm>::value, "Scheduler index mismatch (in_algorithm)");
    static_assert(std::is_same<T, out_algorithm>::value, "Scheduler index mismatch (out_algorithm)");

    // Free all arguments in OutDependencies
    MemoryManagerFree<out_arguments>::free(device_memory_manager, host_memory_manager);

    // Reserve all arguments in InDependencies
    MemoryManagerReserve<argument_manager_t, in_arguments>::reserve(device_memory_manager, host_memory_manager, argument_manager);

    // Print memory manager state
    if (do_print) {
      info_cout << "Sequence step " << I << " \"" << T::name << "\":\n";
      device_memory_manager.print();
      host_memory_manager.print();
    }
  }

  void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config)
  {
    Sch::ConfigureAlgorithmSequence<ConfiguredSequence>::configure(sequence_tuple, config);
  }

  auto get_algorithm_configuration()
  {
    std::map<std::string, std::map<std::string, std::string>> config;
    return Sch::GetSequenceConfiguration<ConfiguredSequence>::get(sequence_tuple, config);
  }
};
