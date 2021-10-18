/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostGlobalEventCut.h"

INSTANTIATE_ALGORITHM(host_global_event_cut::host_global_event_cut_t)

void host_global_event_cut::host_global_event_cut_t::set_arguments_size(
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

void host_global_event_cut::host_global_event_cut_t::operator()(
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

  // Do the host global event cut
  host_function(runtime_options.mep_layout ? host_global_event_cut<true> : host_global_event_cut<false>)(
    arguments);

  // Reduce the size of the event lists to the selected events
  reduce_size<host_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));

  // Copy data to the device
  Allen::copy_async<dev_number_of_events_t, host_number_of_events_t>(arguments, context);
  Allen::copy_async<dev_event_list_output_t, host_event_list_output_t>(arguments, context);

  if (runtime_options.fill_extra_host_buffers) {
    host_buffers.host_number_of_selected_events = first<host_number_of_selected_events_t>(arguments);
    for (unsigned i = 0; i < size<host_event_list_output_t>(arguments); ++i) {
      host_buffers.host_event_list[i] = event_start + data<host_event_list_output_t>(arguments)[i];
    }
  }
}
