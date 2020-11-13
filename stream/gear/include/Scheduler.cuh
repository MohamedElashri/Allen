/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "MemoryManager.cuh"
#include "SchedulerMachinery.cuh"
#include "ArgumentManager.cuh"
#include "Logger.h"
#include <utility>

template<typename ConfiguredSequence, typename ConfiguredArguments, typename ConfiguredSequenceArguments>
struct Scheduler {
  using configured_sequence_t = ConfiguredSequence;
  using configured_sequence_arguments_t = ConfiguredSequenceArguments;

  // Dependencies calculated at compile time
  // Determines what to free (out_deps) and reserve (in_deps)
  // at every iteration.
  using in_deps_t = typename Sch::InDependencies<ConfiguredSequenceArguments>::t;
  using out_deps_t = typename Sch::OutDependencies<ConfiguredSequenceArguments>::t;
  using arguments_tuple_t = ConfiguredArguments;
  using argument_manager_t = ArgumentManager<arguments_tuple_t>;

#ifdef MEMORY_MANAGER_MULTI_ALLOC
  using host_memory_manager_t = MemoryManager<memory_manager_details::Host, memory_manager_details::MultiAlloc>;
  using device_memory_manager_t = MemoryManager<memory_manager_details::Device, memory_manager_details::MultiAlloc>;
#else
  using host_memory_manager_t = MemoryManager<memory_manager_details::Host, memory_manager_details::SingleAlloc>;
  using device_memory_manager_t = MemoryManager<memory_manager_details::Device, memory_manager_details::SingleAlloc>;
#endif

  host_memory_manager_t host_memory_manager {"Host memory manager"};
  device_memory_manager_t device_memory_manager {"Device memory manager"};

  argument_manager_t argument_manager;
  bool do_print = false;

  // Configured sequence
  ConfiguredSequence sequence_tuple;

  Scheduler() = default;
  Scheduler(const Scheduler&) = delete;

  void initialize(const bool param_do_print, const size_t device_requested_mb, const size_t host_requested_mb, const unsigned required_memory_alignment)
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
  template<unsigned long I>
  void setup()
  {
    // in dependencies: Dependencies to be reserved
    // out dependencies: Dependencies to be free'd
    using in_arguments_t = typename std::tuple_element<I, in_deps_t>::type;
    using out_arguments_t = typename std::tuple_element<I, out_deps_t>::type;

    if (do_print) {
      info_cout << "Sequence step " << I << " \"" << std::get<I>(sequence_tuple).name() << "\":\n";
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
