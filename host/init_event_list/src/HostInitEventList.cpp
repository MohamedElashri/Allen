/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostInitEventList.h"

void host_init_event_list::host_init_event_list_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  const auto number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  // Initialize number of events
  set_size<host_event_list_output_t>(arguments, number_of_events);
  set_size<dev_event_list_output_t>(arguments, number_of_events);
}

void host_init_event_list::host_init_event_list_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  const auto number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  // Initialize buffers
  for (unsigned i = 0; i < number_of_events; ++i) {
    data<host_event_list_output_t>(arguments)[i] = i;
  }

  Allen::copy_async<dev_event_list_output_t, host_event_list_output_t>(arguments, context);
}

// The code below would be generated with
// INSTANTIATE_ALGORITHM(host_init_event_list::host_init_event_list_t)

template<>
Allen::TypeErasedAlgorithm Allen::instantiate_algorithm_impl(
  host_init_event_list::host_init_event_list_t*,
  const std::string& name)
{
  auto alg = host_init_event_list::host_init_event_list_t {};
  alg.set_name(name);

  return TypeErasedAlgorithm {
    alg,
    [](const std::any& instance) {
      return std::any_cast<const host_init_event_list::host_init_event_list_t&>(instance).name();
    },
    [](
      const std::any& instance,
      std::any arguments_array,
      std::vector<std::reference_wrapper<ArgumentData>> input_aggregates,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) {
        // Create args array
        auto store = std::any_cast<ArgumentReferences<host_init_event_list::Parameters>::store_t>(arguments_array); // std::array<std::reference_wrapper<ArgumentData>, std::tuple_size_v<parameters_tuple_t>>
        // Create input aggregate t
        auto input_agg_store = ArgumentReferences<host_init_event_list::Parameters>::input_aggregates_t{input_aggregates};
        // Create ArgumentRefManager
        auto arg_ref_manager = ArgumentReferences<host_init_event_list::Parameters>{store, input_agg_store};
        std::any_cast<const host_init_event_list::host_init_event_list_t&>(instance).set_arguments_size(arg_ref_manager, runtime_options, constants, host_buffers);
    }
    // ,
    // [](
    //   const std::any& instance,
    //   std::any arguments_array,
    //   std::vector<std::reference_wrapper<ArgumentData>> input_aggregates,
    //   const RuntimeOptions& runtime_options,
    //   const Constants& constants,
    //   const HostBuffers& host_buffers,
    //   const Allen::Context& context) {
    //     // Create args array
    //     auto store = std::any_cast<ArgumentReferences<host_init_event_list::Parameters>::store_t>(arguments_array); // std::array<std::reference_wrapper<ArgumentData>, std::tuple_size_v<parameters_tuple_t>>
    //     // Create input aggregate t
    //     auto input_agg_store = ArgumentReferences<host_init_event_list::Parameters>::input_aggregates_t{input_aggregates};
    //     // Create ArgumentRefManager
    //     auto arg_ref_manager = ArgumentReferences<host_init_event_list::Parameters>{store, input_agg_store};
    //     std::any_cast<const host_init_event_list::host_init_event_list_t&>(instance)(arg_ref_manager, runtime_options, constants, host_buffers, context);
    // }
    };
}
