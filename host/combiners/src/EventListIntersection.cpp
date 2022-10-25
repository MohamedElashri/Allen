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
#include "EventListIntersection.cuh"

INSTANTIATE_ALGORITHM(event_list_intersection::event_list_intersection_t)

void event_list_intersection::event_list_intersection_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_a_t>(arguments));
  set_size<host_event_list_output_t>(arguments, size<dev_event_list_a_t>(arguments));
  set_size<host_event_list_a_t>(arguments, size<dev_event_list_a_t>(arguments));
  set_size<host_event_list_b_t>(arguments, size<dev_event_list_b_t>(arguments));
}

void event_list_intersection::event_list_intersection_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::copy_async<host_event_list_a_t, dev_event_list_a_t>(arguments, context);
  Allen::copy_async<host_event_list_b_t, dev_event_list_b_t>(arguments, context);
  Allen::synchronize(context);

  unsigned output_number_of_events = 0;

  // Do the intersection between a and b on the host
  for (size_t i = 0; i < size<host_event_list_a_t>(arguments); ++i) {
    const auto element = data<host_event_list_a_t>(arguments)[i];
    for (size_t j = 0; j < size<host_event_list_b_t>(arguments); ++j) {
      if (element == data<host_event_list_b_t>(arguments)[j]) {
        data<host_event_list_output_t>(arguments)[output_number_of_events] = element;
        ++output_number_of_events;
        break;
      }
    }
  }

  // Adjust the size of the output event lists
  reduce_size<host_event_list_output_t>(arguments, output_number_of_events);
  reduce_size<dev_event_list_output_t>(arguments, output_number_of_events);

  // Copy the event list to the device
  Allen::copy_async<dev_event_list_output_t, host_event_list_output_t>(arguments, context);

  if (property<verbosity_t>() >= logger::debug) {
    printf("List intersection:\n From lists:\n a: ");
    for (size_t i = 0; i < size<host_event_list_a_t>(arguments); ++i) {
      printf("%i, ", data<host_event_list_a_t>(arguments)[i]);
    }
    printf("\n b: ");
    for (size_t i = 0; i < size<host_event_list_b_t>(arguments); ++i) {
      printf("%i, ", data<host_event_list_b_t>(arguments)[i]);
    }
    printf("\n To list: ");
    for (size_t i = 0; i < size<host_event_list_output_t>(arguments); ++i) {
      printf("%i, ", data<host_event_list_output_t>(arguments)[i]);
    }
    printf("\n");
  }
}
