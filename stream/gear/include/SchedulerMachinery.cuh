/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <functional>
#include <type_traits>
#include "Logger.h"
#include "Argument.cuh"
#include "ArgumentManager.cuh"
#include "AllenTypeTraits.cuh"

namespace {

    // use constexpr flag to enable/disable contracts 
#ifdef ENABLE_CONTRACTS
    constexpr bool contracts_enabled = true;
#else
    constexpr bool contracts_enabled = false;
#endif
    
  // SFINAE-based invocation of member function iff class provides it.
  // This is just one way to write a type trait, it's not necessarily
  // the best way. You could use the Detection Idiom, for example
  // (http://en.cppreference.com/w/cpp/experimental/is_detected).
  template<typename T, typename = void>
  struct has_member_fn : std::false_type {
  };

  // std::void_t is a C++17 library feature. It can be replaced
  // with your own implementation of void_t, or often by making the
  // decltype expression void, whether by casting or by comma operator
  // (`decltype(expr, void())`)
  template<typename T>
  struct has_member_fn<T, std::void_t<decltype(std::declval<T>().init())>> : std::true_type {
  };
} // namespace

namespace Sch {
  // Get the ArgumentRefManagerType from the function operator()
  template<typename Function>
  struct FunctionTraits;

  template<typename Function, typename T, typename S, typename R, typename... OtherArguments>
  struct FunctionTraits<void (Function::*)(const ArgumentRefManager<T, S, R>&, OtherArguments...) const> {
    using ArgumentRefManagerType = ArgumentRefManager<T, S, R>;
  };

  template<typename Algorithm>
  struct AlgorithmTraits {
    using ArgumentRefManagerType = typename FunctionTraits<decltype(&Algorithm::operator())>::ArgumentRefManagerType;
  };

  // Checks whether an argument T is in any of the arguments specified in the Algorithms
  template<typename T, typename Arguments>
  struct IsInAnyArgumentTuple;

  template<typename T>
  struct IsInAnyArgumentTuple<T, std::tuple<>> : std::false_type {
  };

  template<typename T, typename Arguments, typename... RestOfArguments>
  struct IsInAnyArgumentTuple<T, std::tuple<Arguments, RestOfArguments...>>
    : std::conditional_t<
        TupleContains<T, Arguments>::value,
        std::true_type,
        IsInAnyArgumentTuple<T, std::tuple<RestOfArguments...>>> {
  };

  // A mechanism to only return the arguments in Algorithm
  // that are not on any of the other RestOfArguments
  template<typename Arguments, typename RestOfArguments>
  struct ArgumentsNotIn;

  // If there are no other RestOfArguments, return all the types
  template<typename... Arguments>
  struct ArgumentsNotIn<std::tuple<Arguments...>, std::tuple<>> {
    using t = std::tuple<Arguments...>;
  };

  // Weird case: No dependencies in algo
  template<typename... RestOfArguments>
  struct ArgumentsNotIn<std::tuple<>, std::tuple<RestOfArguments...>> {
    using t = std::tuple<>;
  };

  template<typename Arg, typename... Args, typename OtherArguments, typename... RestOfArguments>
  struct ArgumentsNotIn<std::tuple<Arg, Args...>, std::tuple<OtherArguments, RestOfArguments...>> {
    // Types unused from Args...
    using previous_t = typename ArgumentsNotIn<std::tuple<Args...>, std::tuple<OtherArguments, RestOfArguments...>>::t;

    // We append Arg only if it is _not_ on the previous algorithms
    using t = typename std::conditional_t<
      IsInAnyArgumentTuple<Arg, std::tuple<OtherArguments, RestOfArguments...>>::value,
      previous_t,
      typename TupleAppend<previous_t, Arg>::t>;
  };

  // Consume the algorithms and put their dependencies one by one
  template<typename Arguments>
  struct OutDependenciesImpl;

  template<typename Arguments>
  struct OutDependenciesImpl<std::tuple<Arguments>> {
    using t = std::tuple<>;
  };

  template<typename Arguments, typename NextArguments, typename... RestOfArguments>
  struct OutDependenciesImpl<std::tuple<Arguments, NextArguments, RestOfArguments...>> {
    using previous_t = typename OutDependenciesImpl<std::tuple<NextArguments, RestOfArguments...>>::t;
    using t = typename TupleAppend<
      previous_t,
      typename ArgumentsNotIn<Arguments, std::tuple<NextArguments, RestOfArguments...>>::t>::t;
  };

  // Helper to calculate OUT dependencies
  template<typename ConfiguredSequence>
  struct OutDependencies;

  template<typename Arguments, typename... RestOfArguments>
  struct OutDependencies<std::tuple<Arguments, RestOfArguments...>> {
    using t = typename TupleReverse<typename TupleAppend<
      typename OutDependenciesImpl<typename std::tuple<Arguments, RestOfArguments...>>::t,
      std::tuple<>>::t>::t;
  };

  // Consume the algorithms and put their dependencies one by one
  template<typename Arguments>
  struct InDependenciesImpl;

  template<>
  struct InDependenciesImpl<std::tuple<>> {
    using t = std::tuple<>;
  };

  template<typename Arguments, typename... RestOfArguments>
  struct InDependenciesImpl<std::tuple<Arguments, RestOfArguments...>> {
    using previous_t = typename InDependenciesImpl<std::tuple<RestOfArguments...>>::t;
    using t =
      typename TupleAppend<previous_t, typename ArgumentsNotIn<Arguments, std::tuple<RestOfArguments...>>::t>::t;
  };

  template<typename ConfiguredArguments>
  using InDependencies = InDependenciesImpl<typename TupleReverse<ConfiguredArguments>::t>;

  // Helper to just print the arguments
  template<typename Arguments>
  struct PrintArguments;

  template<>
  struct PrintArguments<std::tuple<>> {
    static constexpr void print() {}
  };

  template<typename Argument>
  struct PrintArguments<std::tuple<Argument>> {
    static constexpr void print() { info_cout << "'" << Argument::name << "'"; }
  };

  template<typename Argument, typename ArgumentSecond, typename... Arguments>
  struct PrintArguments<std::tuple<Argument, ArgumentSecond, Arguments...>> {
    static constexpr void print()
    {
      info_cout << "'" << Argument::name << "', ";
      PrintArguments<std::tuple<ArgumentSecond, Arguments...>>::print();
    }
  };

  // Iterate the types (In or Out) and print them for each iteration
  template<typename Dependencies>
  struct PrintAlgorithmDependencies;

  template<>
  struct PrintAlgorithmDependencies<std::tuple<>> {
    static constexpr void print() {};
  };

  template<typename Algorithm, typename... Arguments, typename... Dependencies>
  struct PrintAlgorithmDependencies<
    std::tuple<ScheduledDependencies<Algorithm, std::tuple<Arguments...>>, Dependencies...>> {
    static constexpr void print()
    {
      // info_cout << "  ['" << Algorithm::name << "', [";
      // PrintArguments<std::tuple<Arguments...>>::print();
      // info_cout << "]]," << std::endl;

      PrintAlgorithmDependencies<std::tuple<Dependencies...>>::print();
    }
  };

  // Print the configured sequence
  template<typename Dependencies>
  struct PrintAlgorithmSequence;

  template<>
  struct PrintAlgorithmSequence<std::tuple<>> {
    static constexpr void print() {};
  };

  template<typename Algorithm, typename... Algorithms>
  struct PrintAlgorithmSequence<std::tuple<Algorithm, Algorithms...>> {
    static constexpr void print()
    {
      // info_cout << " " << Algorithm::name << std::endl;
      PrintAlgorithmSequence<std::tuple<Algorithms...>>::print();
    }
  };

  template<typename Dependencies>
  struct PrintAlgorithmSequenceDetailed;

  template<>
  struct PrintAlgorithmSequenceDetailed<std::tuple<>> {
    static constexpr void print() {};
  };

  template<typename Algorithm, typename... Algorithms>
  struct PrintAlgorithmSequenceDetailed<std::tuple<Algorithm, Algorithms...>> {
    static constexpr void print()
    {
      // info_cout << "  ['" << Algorithm::name << "', [";
      // PrintArguments<typename Algorithm::Arguments>::print();
      // info_cout << "]]," << std::endl;

      PrintAlgorithmSequenceDetailed<std::tuple<Algorithms...>>::print();
    }
  };

  /**
   * @brief Produces a list of argument references.
   */
  template<typename ArgumentsTuple, typename ArgumentRefManager, typename ConfiguredArguments>
  struct ProduceArgumentsTupleHelper;

  template<typename ArgumentsTuple, typename ArgumentRefManager, typename... ConfiguredArguments>
  struct ProduceArgumentsTupleHelper<ArgumentsTuple, ArgumentRefManager, std::tuple<ConfiguredArguments...>> {
    constexpr static auto produce(std::array<ArgumentData, std::tuple_size_v<ArgumentsTuple>>& arguments_array)
    {
      return ArgumentRefManager {{arguments_array[index_of_v<ConfiguredArguments,ArgumentsTuple>]...}};
    }
  };

  /**
   * @brief Produces a single algorithm with references to arguments.
   */
  template<typename ArgumentsTuple, typename Algorithm, typename ConfiguredArguments>
  struct ProduceArgumentsTuple {
    constexpr static auto produce(std::array<ArgumentData, std::tuple_size_v<ArgumentsTuple>>& arguments_database)
    {
      return ProduceArgumentsTupleHelper<
        ArgumentsTuple,
        typename AlgorithmTraits<Algorithm>::ArgumentRefManagerType,
        ConfiguredArguments>::produce(arguments_database);
    }
  };

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
    using preconditions = typename TupleAppend<typename recursive_contracts::preconditions, A>::t;
    using postconditions = typename recursive_contracts::postconditions;
  };

  template<typename A, typename... T>
  struct AlgorithmContracts<
    std::tuple<A, T...>,
    std::enable_if_t<std::is_base_of_v<Allen::contract::Postcondition, A>>> {
    using recursive_contracts = AlgorithmContracts<std::tuple<T...>>;
    using preconditions = typename recursive_contracts::preconditions;
    using postconditions = typename TupleAppend<typename recursive_contracts::postconditions, A>::t;
  };

  /**
   * @brief Runs the sequence tuple (implementation).
   */

  template<typename Scheduler, unsigned long I, unsigned long... Is>
  void run_sequence_tuple(
      Scheduler& scheduler,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context,
      std::index_sequence<I,Is...>)
    {
      using t = std::tuple_element_t<I, typename Scheduler::configured_sequence_t>;
      using configured_arguments_t = std::tuple_element_t<I, typename Scheduler::configured_sequence_arguments_t>;

      auto arguments_tuple =
        ProduceArgumentsTuple<typename Scheduler::arguments_tuple_t, t, configured_arguments_t>::produce(
          scheduler.argument_manager.argument_database());

      // Get pre and postconditions -- conditional on `contracts_enabled`
      // Starting at -O1, gcc will entirely remove the contracts code when not enabled, see https://godbolt.org/z/67jxx7
      using algorithm_contracts = AlgorithmContracts<typename t::contracts>;
      auto preconditions = std::conditional_t< contracts_enabled, typename algorithm_contracts::preconditions, std::tuple<>> {};
      auto postconditions = std::conditional_t< contracts_enabled, typename algorithm_contracts::postconditions, std::tuple<>> {};

      // Set location
      const auto location = std::invoke( scheduler.vtbls[I].name, scheduler.vtbls[I].algorithm );
      std::apply(
        [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
        preconditions);
      std::apply(
        [&](auto&... contract) { (contract.set_location(location, demangle<decltype(contract)>()), ...); },
        postconditions);

      // Sets the arguments sizes
      std::get<I>(scheduler.sequence_tuple)
        .set_arguments_size(arguments_tuple, runtime_options, constants, host_buffers);

      // Setup algorithm, reserving / freeing memory buffers
      scheduler.template setup<I>();

      // Run preconditions
      std::apply(
        [&](const auto&... contract) {
          (contract(arguments_tuple, runtime_options, constants, context), ...);
        },
        preconditions);

      try {
        // Invoke operator() of the algorithm
        std::get<I>(scheduler.sequence_tuple)(arguments_tuple, runtime_options, constants, host_buffers, context);
      } catch (std::invalid_argument& e) {
        fprintf(
          stderr,
          "Execution of algorithm %s raised an exception\n",
          std::invoke( scheduler.vtbls[I].name, scheduler.vtbls[I].algorithm ).c_str());
        throw e;
      }

      // Run postconditions
      std::apply(
        [&](const auto&... contract) {
          (contract(arguments_tuple, runtime_options, constants, context), ...);
        },
        postconditions);

      if constexpr (sizeof...(Is)!=0) {
         run_sequence_tuple( scheduler, runtime_options, constants, host_buffers, context, std::index_sequence<Is...>{});
      }
    }


  /**
   * @brief Runs the PrChecker for all configured algorithms in the sequence.
   */
  template<typename ConfiguredSequence, typename Arguments>
  struct RunChecker;

  template<typename... Arguments>
  struct RunChecker<std::tuple<>, std::tuple<Arguments...>> {
    constexpr static void check(Arguments&&...) {}
  };

  template<typename Algorithm, typename... Algorithms, typename... Arguments>
  struct RunChecker<std::tuple<Algorithm, Algorithms...>, std::tuple<Arguments...>> {
    constexpr static void check(Arguments&&... arguments)
    {
      SequenceVisitor<Algorithm>::check(std::forward<Arguments>(arguments)...);

      RunChecker<std::tuple<Algorithms...>, std::tuple<Arguments...>>::check(std::forward<Arguments>(arguments)...);
    }
  };
} // namespace Sch
