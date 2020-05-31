/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostInitEventList.h"

void host_init_event_list::host_init_event_list_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  const auto event_start = std::get<0>(runtime_options.event_interval);
  const auto event_end = std::get<1>(runtime_options.event_interval);

  // Initialize number of events
  set_size<host_number_of_events_t>(arguments, event_end - event_start);
  set_size<host_event_list_t>(arguments, event_end - event_start);
  set_size<dev_event_list_t>(arguments, event_end - event_start);
}

void host_init_event_list::host_init_event_list_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  const auto number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  // Initialize number of events
  data<host_number_of_events_t>(arguments)[0] = number_of_events;

  // Initialize buffers
  for (unsigned i = 0; i < number_of_events; ++i) {
    data<host_event_list_t>(arguments)[i] = i;
  }

  copy<dev_event_list_t, host_event_list_t>(arguments, cuda_stream);
}