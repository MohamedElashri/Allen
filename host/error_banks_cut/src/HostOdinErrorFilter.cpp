/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostOdinErrorFilter.h"

INSTANTIATE_ALGORITHM(host_odin_error_filter::host_odin_error_filter_t)

void host_odin_error_filter::host_odin_error_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  const auto number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_events_t>(arguments, 1);
  set_size<host_event_list_output_t>(arguments, number_of_events);
  set_size<dev_number_of_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, number_of_events);
}

void host_odin_error_filter::host_odin_error_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  const auto event_start = std::get<0>(runtime_options.event_interval);
  const auto event_end = std::get<1>(runtime_options.event_interval);
  const auto number_of_events = event_end - event_start;

  // Initialize number of events
  data<host_number_of_events_t>(arguments)[0] = number_of_events;

  auto event_mask_odin = runtime_options.input_provider->event_mask(runtime_options.slice_index);

  unsigned size_of_list = 0;
  for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
    unsigned event_number = event_index;

    if (event_mask_odin[event_number] == 1) {
      data<host_event_list_output_t>(arguments)[size_of_list++] = event_number;
    }
  }

  data<host_number_of_selected_events_t>(arguments)[0] = size_of_list;

  // Reduce the size of the event lists to the selected events
  reduce_size<host_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));

  // Copy data to the device
  Allen::copy_async<dev_number_of_events_t, host_number_of_events_t>(arguments, context);
  Allen::copy_async<dev_event_list_output_t, host_event_list_output_t>(arguments, context);

  host_buffers.host_number_of_selected_events = first<host_number_of_selected_events_t>(arguments);
}
