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
    [](const std::any& instance) { return std::any_cast<host_init_event_list::host_init_event_list_t>(instance).name(); },
    [](
      std::any arguments_array,
      std::vector<std::vector<std::reference_wrapper<ArgumentData>>> input_aggregates) {
      // Create args array
      auto store = std::any_cast<ArgumentReferences<host_init_event_list::Parameters>::store_t>(
        arguments_array);
      // Create input aggregate t
      auto input_agg_store =
        ArgumentReferences<host_init_event_list::Parameters>::input_aggregates_t {Allen::gen_input_aggregates_tuple(
          input_aggregates,
          std::make_index_sequence<
            std::tuple_size_v<ArgumentReferences<host_init_event_list::Parameters>::input_aggregates_t>> {})};
      // Create ArgumentRefManager
      auto arg_ref_manager = ArgumentReferences<host_init_event_list::Parameters> {store, input_agg_store};
      return std::any{arg_ref_manager};
    },
    [](
      const std::any& instance,
      std::any& arg_ref_manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) {
      std::any_cast<const host_init_event_list::host_init_event_list_t&>(instance).set_arguments_size(
        std::any_cast<ArgumentReferences<host_init_event_list::Parameters>&>(arg_ref_manager), runtime_options, constants, host_buffers);
    },
    [](
      const std::any& instance,
      std::any& arg_ref_manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) {
      std::any_cast<const host_init_event_list::host_init_event_list_t&>(instance)(
        std::any_cast<ArgumentReferences<host_init_event_list::Parameters>&>(arg_ref_manager), runtime_options, constants, host_buffers, context);
    },
    [](
      std::any& instance) {
      if constexpr (Allen::has_init_member_fn<host_init_event_list::host_init_event_list_t>::value) {
        std::any_cast<host_init_event_list::host_init_event_list_t&>(instance).init();
      }
    },
    [](
      std::any& instance,
      const std::map<std::string, std::string>& algo_config) {
      std::any_cast<host_init_event_list::host_init_event_list_t&>(instance).set_properties(algo_config);
    }
  };
}
