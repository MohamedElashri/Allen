/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostOdinErrorFilter.h"

INSTANTIATE_ALGORITHM(host_odin_error_filter::host_odin_error_filter_t)

void host_odin_error_filter::host_odin_error_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_mask_t>(arguments));
}

void host_odin_error_filter::host_odin_error_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  data<host_number_of_selected_events_t>(arguments)[0] = size<dev_event_mask_t>(arguments);
  Allen::copy_async<dev_event_list_output_t, dev_event_mask_t>(arguments, context);
}
