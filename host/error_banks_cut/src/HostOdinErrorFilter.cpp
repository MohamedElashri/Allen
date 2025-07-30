/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HostOdinErrorFilter.h"

INSTANTIATE_ALGORITHM(host_odin_error_filter::host_odin_error_filter_t)

void host_odin_error_filter::host_odin_error_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_mask_t>(arguments));
}

void host_odin_error_filter::host_odin_error_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  data<host_number_of_selected_events_t>(arguments)[0] = size<dev_event_mask_t>(arguments);
  Allen::copy_async<dev_event_list_output_t, dev_event_mask_t>(arguments, context);
}
