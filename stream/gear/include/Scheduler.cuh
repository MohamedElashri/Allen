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

namespace details {

    template <auto I, typename Callable, typename... Tuples>
    constexpr auto invoke_at(Callable&& f, Tuples&&... tuples) {
        return std::invoke( f, std::get<I>(std::forward<Tuples>(tuples))...);
    }       
    template < typename Callable, typename... Tuples ,std::size_t... Is >
    constexpr void invoke_for_each_slice_impl(  std::index_sequence<Is...>,  Callable&& f, Tuples&&... tuples ) {
        (invoke_at<Is>(std::forward<Callable>(f), std::forward<Tuples>(tuples)...), ...);
    } 
    template <typename Callable, typename Tuple, typename... Tuples  >
    constexpr void invoke_for_each_slice(Callable&& f, Tuple&& tuple, Tuples&&... tuples ) {
        constexpr auto N = std::tuple_size_v<std::remove_reference_t<Tuple>>;
        static_assert( ( ( N == std::tuple_size_v<std::remove_reference_t<Tuples>> ) && ... ) );
        invoke_for_each_slice_impl(  std::make_index_sequence<N>{} , std::forward<Callable>(f), std::forward<Tuple>(tuple), std::forward<Tuples>(tuples)...);
    }

    struct VTable {
        void *algorithm = nullptr;
        void (*configure)(void* self, const std::map<std::string, std::map<std::string, std::string>>& config) = nullptr;
        void (*get_configuration)(const void* self,std::map<std::string, std::map<std::string, std::string>>& config) = nullptr;
        std::string (*name)(const void* self) = nullptr;
        // void (*set_arguments_size)(void* self, arguments_tuple, const RuntimeOptoons&, const Constants&, HostBuffers&) = nullptr;
    };

    template <typename Alg>
    constexpr auto vtable_for(Alg& alg) {
        return VTable{ 
            // Payload
            /* .algorithm = */ &alg,
            // Configure constants for algorithms 
            /* .configure = */ [](void *self,  const std::map<std::string, std::map<std::string, std::string>>& config) {
                    auto *algorithm = static_cast<Alg*>(self);
                    auto c = config.find(algorithm->name());
                    if (c != config.end()) algorithm->set_properties(c->second);
                    // * Invoke void initialize() const, iff it exists
                    if constexpr (has_member_fn<Alg>::value) { algorithm->init(); };
            },
            /* .get_configuration = */ [](const void* self,std::map<std::string, std::map<std::string, std::string>>& config) {
                    auto *algorithm = static_cast<const Alg*>(self);
                    config.emplace(algorithm->name(), algorithm->get_properties() );
            },
            /* .name = */ [](const void* self) { return static_cast<const Alg*>(self)->name(); }
        };
    }
}


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
  configured_sequence_t sequence_tuple; // TODO: GR: remove any direct use of this variable...
  std::array< details::VTable, std::tuple_size_v<configured_sequence_t> > vtbls;

  Scheduler() {
      details::invoke_for_each_slice( [](auto& alg, details::VTable& vtbl) { vtbl = details::vtable_for(alg); } , sequence_tuple,  vtbls   );
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
      info_cout << "Sequence step " << I << " \"" << std::invoke( vtbls[I].name, vtbls[I].algorithm ) << "\":\n";
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

  // Configure constants for algorithms in the sequence
  void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config)
  {
    std::for_each( vtbls.begin(), vtbls.end(), [&config](auto& vtbl) {
        std::invoke( vtbl.configure, vtbl.algorithm, config );
    } );
  }

  // Return constants for algorithms in the sequence
  auto get_algorithm_configuration()
  {
    std::map<std::string, std::map<std::string, std::string>> config;
    std::for_each( vtbls.begin(), vtbls.end(), [&config](auto& vtbl) {
        std::invoke( vtbl.get_configuration, vtbl.algorithm, config );
    } );
    return config;
  }

  //  Runs a sequence of algorithms.
  void run( const RuntimeOptions& runtime_options,  const Constants& constants, HostBuffers* host_buffers, const Allen::Context& context ) {
    //TODO: GR: type erase me
    constexpr auto N = std::tuple_size_v<typename Scheduler::configured_sequence_t>;
    static_assert(N>0);
    Sch::run_sequence_tuple(*this, runtime_options, constants, *host_buffers, context, std::make_index_sequence<N>{});
  }
};
