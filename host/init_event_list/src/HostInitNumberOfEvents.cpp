/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HostInitNumberOfEvents.h"

void host_init_number_of_events::host_init_number_of_events_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // Initialize number of events
  set_size<host_number_of_events_t>(arguments, 1);
  set_size<dev_number_of_events_t>(arguments, 1);
}

void host_init_number_of_events::host_init_number_of_events_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  const auto number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  // Initialize the number of events
  data<host_number_of_events_t>(arguments)[0] = number_of_events;
  Allen::copy_async<dev_number_of_events_t, host_number_of_events_t>(arguments, context);
}
