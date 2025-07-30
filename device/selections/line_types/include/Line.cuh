/*****************************************************************************\
 * (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
 \*****************************************************************************/
#pragma once

#include <string>
#include <ArgumentOps.cuh>
#include <DeterministicScaler.cuh>
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include <tuple>
#include <ROOTHeaders.h>
#include "ROOTService.h"
#include "ODINBank.cuh"

// Helper macro to explicitly instantiate lines
#define INSTANTIATE_LINE(DERIVED, PARAMETERS)                                                                     \
  template void Line<DERIVED, PARAMETERS>::operator()(                                                            \
    const ArgumentReferences<PARAMETERS>&, const RuntimeOptions&, const Constants&, const Allen::Context&) const; \
  template __device__ void process_line<DERIVED, PARAMETERS>(                                                     \
    char*,                                                                                                        \
    uint32_t*,                                                                                                    \
    unsigned*,                                                                                                    \
    const LineData*,                                                                                              \
    const ODINData*,                                                                                              \
    const unsigned*,                                                                                              \
    const unsigned,                                                                                               \
    const unsigned,                                                                                               \
    const unsigned,                                                                                               \
    const unsigned);                                                                                              \
  template void line_output_monitor<DERIVED, PARAMETERS>(char*, const RuntimeOptions&, const Allen::Context&);    \
  INSTANTIATE_ALGORITHM(DERIVED)

template<typename Derived, typename Parameters>
using type_erased_tuple_t =
  std::tuple<Parameters, ArgumentReferences<Parameters>, const Derived*, typename Derived::DeviceProperties>;

struct LineData {
  float pre_scaler {0};
  uint32_t pre_scaler_hash {0};

  float post_scaler {0};
  uint32_t post_scaler_hash {0};

  unsigned decisions_size {0};

  const mask_t* event_list {nullptr};
  unsigned event_list_size {0};

  bool enable_monitoring {false};
  bool enable_tupling {false};

  Allen::IMultiEventContainer* particle_container_ptr {nullptr};
};

template<typename Derived, typename Parameters>
struct Line {
private:
  uint32_t m_pre_scaler_hash;
  uint32_t m_post_scaler_hash;

  template<typename TupleType, typename FuncT, std::size_t... seq_t>
  void for_each_internal(FuncT& f, std::integer_sequence<std::size_t, seq_t...> /*seq*/) const
  {
    (f.template operator()<typename std::tuple_element<seq_t, TupleType>::type>(), ...);
  }
  template<typename FuncT, typename TupleType>
  void for_each(FuncT& f) const
  {
    std::make_index_sequence<std::tuple_size<TupleType>::value> sequence;
    for_each_internal<TupleType>(f, sequence);
  }

  // under C++20  - these can be converted to lambda functions - for now have to do
  // lambdas the old fashioned way
  struct set_size_functor {
    set_size_functor(ArgumentReferences<Parameters>& arguments, std::size_t size) : arguments(arguments), size(size) {}
    ArgumentReferences<Parameters>& arguments;
    std::size_t size;
    template<typename f>
    void operator()()
    {
      Allen::ArgumentOperations::set_size<f>(arguments, size);
    }
  };

  struct initialize_functor {
    initialize_functor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) :
      arguments(arguments), context(context)
    {}
    const ArgumentReferences<Parameters>& arguments;
    const Allen::Context& context;
    template<typename f>
    void operator()()
    {
      Allen::memset_async<f>(arguments, -1, context);
    }
  };

  /**
   * @brief Checks if t is all 1s.
   */
  template<typename T>
  bool is_default_value(T t) const
  {
    signed char* c = reinterpret_cast<signed char*>(&t);
    for (unsigned i = 0; i < sizeof(T); ++i) {
      if (c[i] != -1) {
        return false;
      }
    }
    return true;
  }

public:
  void init()
  {
    auto derived_instance = static_cast<const Derived*>(this);
    const std::string pre_scaler_hash_string =
      derived_instance->template get_property<std::string>("pre_scaler_hash_string");
    const std::string post_scaler_hash_string =
      derived_instance->template get_property<std::string>("post_scaler_hash_string");

    if (pre_scaler_hash_string.empty() || post_scaler_hash_string.empty()) {
      throw HashNotPopulatedException(derived_instance->name());
    }

    m_pre_scaler_hash = mixString(pre_scaler_hash_string.size(), pre_scaler_hash_string);
    m_post_scaler_hash = mixString(post_scaler_hash_string.size(), post_scaler_hash_string);
  }

  void operator()(
    const ArgumentReferences<Parameters>&,
    const RuntimeOptions&,
    const Constants&,
    const Allen::Context& context) const;

  /**
   * @brief Default monitor function.
   */
  void init_tuples(
    [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
    [[maybe_unused]] const Allen::Context& context) const
  {
    if constexpr (Allen::has_monitoring_types<Derived>::value) {
      initialize_functor f(arguments, context);
      for_each<decltype(f), typename Derived::monitoring_types>(f);
    }
  }

  void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const
  {
    Allen::ArgumentOperations::set_size<typename Parameters::host_line_data_t>(arguments, 1);

    // Set the size of the type-erased fn parameters
    Allen::ArgumentOperations::set_size<typename Parameters::host_fn_parameters_t>(
      arguments, sizeof(type_erased_tuple_t<Derived, Parameters>));

    if constexpr (Allen::has_monitoring_types<Derived>::value) {
      auto derived_instance = static_cast<const Derived*>(this);
      if (derived_instance->template get_property<bool>("enable_tupling")) {
        set_size_functor ssf(arguments, Derived::get_decisions_size(arguments));
        for_each<set_size_functor, typename Derived::monitoring_types>(ssf);
      }
    }
  }

  struct DeviceProperties {
    DeviceProperties(const Derived&, const Allen::Context&) {}
  };

  template<typename T, typename U>
  static __device__ void monitor(const Parameters&, U, T, unsigned, bool)
  {}
  template<typename T>
  static __device__ bool fill_tuples(const Parameters&, T, unsigned, bool)
  {
    return false;
  }

  template<std::size_t N, typename lv, typename rv>
  void set_equal(lv& l, const rv& r, std::size_t index) const
  {
    std::get<N>(l) = std::get<N>(r)[index];
  }

  template<std::size_t N, typename ValueType>
  void make_branch(
    handleROOTSvc& handler,
    TTree* tree,
    const ArgumentReferences<Parameters>& arguments,
    ValueType& values) const
  {
    using TupleType = typename Derived::monitoring_types;
    handler.branch(
      tree,
      Allen::ArgumentOperations::name<typename std::tuple_element<N, TupleType>::type>(arguments),
      std::get<N>(values));
  }
  template<std::size_t... seq_t>
  void do_monitoring(
    const ArgumentReferences<Parameters>& arguments,
    handleROOTSvc& handler,
    std::integer_sequence<std::size_t, seq_t...> /*int_seq*/,
    const Allen::Context& context) const
  {
    using TupleType = typename Derived::monitoring_types;
    auto host_v =
      std::tuple {Allen::ArgumentOperations::make_host_buffer<typename std::tuple_element<seq_t, TupleType>::type>(
        arguments, context)...};
    auto values = std::tuple {typename std::tuple_element<seq_t, TupleType>::type::type()...};
    size_t ev = 0;
    auto tree = handler.tree("monitor_tree");
    if (tree == nullptr) return;
    (make_branch<seq_t>(handler, tree, arguments, values), ...);
    handler.branch(tree, "ev", ev);
    auto i0 = tree->GetEntries();
    for (unsigned i = 0; i != std::get<0>(host_v).size(); ++i) {
      if (!is_default_value(std::get<0>(host_v)[i])) {
        (set_equal<seq_t>(values, host_v, i), ...);
        ev = i0 + i;
        tree->Fill();
      }
    }
  }

  void output_tuples(
    [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
    [[maybe_unused]] const RuntimeOptions& runtime_options,
    [[maybe_unused]] const Allen::Context& context) const
  {
    if constexpr (Allen::has_monitoring_types<Derived>::value) {
      std::make_index_sequence<std::tuple_size<typename Derived::monitoring_types>::value> sequence;
      auto derived_instance = static_cast<const Derived*>(this);
      auto handler = runtime_options.root_service->handle(derived_instance->name());
      do_monitoring(arguments, handler, sequence, context);
    }
  }

  __device__ static unsigned input_size(const Parameters& parameters, unsigned event_number)
  {
    return Derived::offset(parameters, event_number + 1) - Derived::offset(parameters, event_number);
  }
};

template<typename Derived, typename Parameters>
void line_output_monitor(char* input, const RuntimeOptions& runtime_options, const Allen::Context& context)
{
  if constexpr (Allen::has_monitoring_types<Derived>::value) {
    if (input != nullptr) {
      const auto& type_casted_input = *reinterpret_cast<type_erased_tuple_t<Derived, Parameters>*>(input);
      auto derived_instance = std::get<2>(type_casted_input);
      if (derived_instance->template get_property<bool>("enable_tupling")) {
        derived_instance->output_tuples(std::get<1>(type_casted_input), runtime_options, context);
      }
    }
  }
}

#if defined(DEVICE_COMPILER)
template<typename Derived, typename Parameters>
__device__ void process_line(
  char* input,
  uint32_t* decisions,
  unsigned* decisions_offsets,
  [[maybe_unused]] const LineData* dev_line_data,
  const ODINData* dev_odin_data,
  const unsigned* pre_scale_event_list,
  const unsigned pre_scale_event_list_size,
  const unsigned line_offset,
  const unsigned line_index,
  const unsigned number_of_events)
{
  const auto& type_casted_input = *reinterpret_cast<type_erased_tuple_t<Derived, Parameters>*>(input);
  const auto& parameters = std::get<0>(type_casted_input);

  // Do initialization for all events, regardless of mask
  for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
    decisions_offsets[i] = line_offset + Derived::offset(parameters, i);
  }

  // Switch between 3 settings:
  // * 1 thread per event
  // * 1 thread per object
  // * balanced: (32 threads per objects, 8 event per block)
  const auto threads_per_event =
    (dev_line_data->decisions_size == number_of_events) ? 1 : (pre_scale_event_list_size == 1) ? blockDim.x : warp_size;
  const auto events_per_block = blockDim.x / threads_per_event;

  for (unsigned j = threadIdx.x / threads_per_event; j < pre_scale_event_list_size; j += events_per_block) {
    const auto event_number = pre_scale_event_list[j];

    // * Populate decisions
    const unsigned input_size = Derived::input_size(parameters, event_number);
    for (unsigned i = threadIdx.x % threads_per_event; i < input_size; i += threads_per_event) {
      const auto input = Derived::get_input(parameters, event_number, i);
      bool decision;
      if constexpr (!std::is_same_v<
                      typename Line<Derived, Parameters>::DeviceProperties,
                      typename Derived::DeviceProperties>) {
        const auto properties = std::get<3>(type_casted_input);
        decision = Derived::select(parameters, properties, input);
      }
      else {
        decision = Derived::select(parameters, input);
      }

      unsigned span_index = line_index * number_of_events + event_number;
      unsigned index = (line_offset + Derived::offset(parameters, event_number)) / 32 + span_index + i / 32;
      if (decision) atomicOr(&decisions[index], 1 << (i % 32));

      if (dev_line_data->enable_monitoring) {
        unsigned index = Derived::offset(parameters, event_number) + i;
        const auto properties = std::get<3>(type_casted_input);
        Derived::monitor(parameters, properties, input, index, decision);
      }

      if constexpr (Allen::has_monitoring_types<Derived>::value) {
        if (dev_line_data->enable_tupling) {
          unsigned index = Derived::offset(parameters, event_number) + i;
          bool do_fill;
          if constexpr (!std::is_same_v<
                          typename Line<Derived, Parameters>::DeviceProperties,
                          typename Derived::DeviceProperties>) {
            const auto properties = std::get<3>(type_casted_input);
            do_fill = Derived::fill_tuples(parameters, properties, input, index, decision);
          }
          else {
            do_fill = Derived::fill_tuples(parameters, input, index, decision);
          }
          if (do_fill) {
            LHCb::ODIN odin {dev_odin_data[event_number]};
            if constexpr (Allen::monitoring_has_evtNo<Parameters>::value) {
              parameters.evtNo[index] = odin.eventNumber();
            }
            if constexpr (Allen::monitoring_has_runNo<Parameters>::value) {
              parameters.runNo[index] = odin.runNumber();
            }
          }
        }
      }
    }
  }
}

template<typename Derived, typename Parameters>
void Line<Derived, Parameters>::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  [[maybe_unused]] const Allen::Context& context) const
{
  const auto* derived_instance = static_cast<const Derived*>(this);

  // Copy infos needed by GatherSelections to an output:
  auto& line_data = Allen::ArgumentOperations::data<typename Parameters::host_line_data_t>(arguments)[0];
  line_data.pre_scaler = derived_instance->template get_property<float>("pre_scaler");
  line_data.pre_scaler_hash = m_pre_scaler_hash;
  line_data.post_scaler = derived_instance->template get_property<float>("post_scaler");
  line_data.post_scaler_hash = m_post_scaler_hash;
  line_data.decisions_size = Derived::get_decisions_size(arguments);
  line_data.event_list = Allen::ArgumentOperations::data<typename Parameters::dev_event_list_t>(arguments);
  line_data.event_list_size = Allen::ArgumentOperations::size<typename Parameters::dev_event_list_t>(arguments);
  line_data.enable_monitoring = derived_instance->template get_property<bool>("enable_monitoring");
  line_data.enable_tupling = derived_instance->template get_property<bool>("enable_tupling");

  if constexpr (Allen::has_dev_particle_container<
                  Derived,
                  Allen::Store::device_datatype,
                  Allen::Store::input_datatype>::value) {
    const auto ptr = static_cast<const Allen::IMultiEventContainer*>(
      Allen::ArgumentOperations::data<typename Parameters::dev_particle_container_t>(arguments));
    line_data.particle_container_ptr = const_cast<Allen::IMultiEventContainer*>(ptr);
  }
  else {
    line_data.particle_container_ptr = nullptr;
  }

  // Delay the execution of the line: Pass the parameters
  auto parameters = std::make_tuple(
    derived_instance->make_parameters(1, 1, 0, arguments),
    arguments,
    derived_instance,
    typename Derived::DeviceProperties(*derived_instance, context));

  assert(sizeof(type_erased_tuple_t<Derived, Parameters>) == sizeof(parameters));
  std::memcpy(
    Allen::ArgumentOperations::data<typename Parameters::host_fn_parameters_t>(arguments),
    &parameters,
    sizeof(parameters));

  if constexpr (Allen::has_monitoring_types<Derived>::value) {
    if (derived_instance->template get_property<bool>("enable_tupling")) {
      derived_instance->init_tuples(arguments, context);
    }
  }
}
#endif
