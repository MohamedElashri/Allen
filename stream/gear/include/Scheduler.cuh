#pragma once

#include "MemoryManager.cuh"
#include "SchedulerMachinery.cuh"
#include "ArgumentManager.cuh"
#include "Logger.h"
#include "InitEventList.cuh"
#include <utility>

template<typename ArgumentsTuple, typename Argument>
struct ProduceSingleArgument {
  constexpr static Argument& produce(ArgumentsTuple& arguments_tuple) {
    return std::get<Argument>(arguments_tuple);
  }
};


template<typename ArgumentsTuple, typename Arguments>
struct ProduceArguments;

template<typename ArgumentsTuple, typename... Arguments>
struct ProduceArguments<ArgumentsTuple, std::tuple<Arguments...>> {
  constexpr static std::tuple<Arguments&...> produce(ArgumentsTuple& arguments_tuple) {
    return {
      ProduceSingleArgument<ArgumentsTuple, Arguments>::produce(arguments_tuple)...
    };
  }
};


template<typename ArgumentsTuple, typename Algorithm>
struct ProduceAlgorithm {
  constexpr static Algorithm produce(ArgumentsTuple& arguments_tuple) {
    return Algorithm{
      ProduceArguments<ArgumentsTuple, typename Algorithm::Arguments>::produce(arguments_tuple)
    };
  }
};


template<typename ArgumentsTuple, typename Algorithms>
struct ProduceSequence;

template<typename ArgumentsTuple, typename... Algorithms>
struct ProduceSequence<ArgumentsTuple, std::tuple<Algorithms...>> {
  constexpr static std::tuple<Algorithms...> produce(ArgumentsTuple& arguments_tuple) {
    return std::tuple<Algorithms...>{
      ProduceAlgorithm<ArgumentsTuple, Algorithms>::produce(arguments_tuple)...
    };
  }
};


template<typename ConfiguredSequence, typename OutputArguments>
struct Scheduler {
  // Dependencies calculated at compile time
  // Determines what to free (out_deps) and reserve (in_deps)
  // at every iteration.
  using in_deps_t = typename Sch::InDependencies<ConfiguredSequence>::t;
  using out_deps_t = typename Sch::OutDependencies<ConfiguredSequence, OutputArguments>::t;
  using arguments_tuple_t = typename Sch::ArgumentsTuple<in_deps_t>::t;
  using argument_manager_t = ArgumentManager<arguments_tuple_t>;

  in_deps_t in_deps;
  out_deps_t out_deps;
  MemoryManager memory_manager;
  argument_manager_t argument_manager;
  bool do_print = false;

  // Sequence and arguments
  ConfiguredSequence sequence_tuple {
    ProduceSequence<arguments_tuple_t, ConfiguredSequence>::produce(argument_manager.arguments_tuple)
  };
  
  // ConfiguredSequence sequence_tuple {{arguments_tuple}};
  // std::tuple<init_event_list_t> sequence_tuple {arguments_tuple};
  // std::tuple<init_event_list_t> sequence_tuple {init_event_list_t{arguments_tuple}};

  Scheduler() = default;
  Scheduler(const Scheduler&) = default;

  void initialize(
    const bool param_do_print,
    const size_t reserved_mb,
    char* base_pointer)
  {
    do_print = param_do_print;

    // Set max mb to memory_manager
    memory_manager.set_reserved_memory(reserved_mb);
    argument_manager.set_base_pointer(base_pointer);

    if (logger::ll.verbosityLevel >= logger::verbose) {
      verbose_cout << "IN deps" << std::endl;
      Sch::PrintAlgorithmDependencies<in_deps_t>::print();

      // verbose_cout << "OUT deps" << std::endl;
      // Sch::PrintAlgorithmDependencies<out_deps_t>::print();
    }
  }

  /**
   * @brief Resets the memory manager.
   */
  void reset() {
    memory_manager.free_all();
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
  void setup() {
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
    MemoryManagerFree<out_arguments>::free(memory_manager);

    // Reserve all arguments in InDependencies
    MemoryManagerReserve<argument_manager_t, in_arguments>::reserve(memory_manager, argument_manager);

    // Print memory manager state
    if (do_print) {
      info_cout << "Sequence step " << I << " \"" << T::name << "\":" << std::endl;
      memory_manager.print();
    }
  }
};
