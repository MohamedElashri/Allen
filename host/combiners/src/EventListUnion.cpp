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
#include "EventListUnion.cuh"

void event_list_union::event_list_union_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_event_list_output_t>(
    arguments, size<dev_event_list_a_t>(arguments) + size<dev_event_list_b_t>(arguments));
  set_size<host_event_list_output_t>(
    arguments, size<dev_event_list_a_t>(arguments) + size<dev_event_list_b_t>(arguments));
  set_size<host_event_list_a_t>(arguments, size<dev_event_list_a_t>(arguments));
  set_size<host_event_list_b_t>(arguments, size<dev_event_list_b_t>(arguments));
}

void event_list_union::event_list_union_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  copy<host_event_list_a_t, dev_event_list_a_t>(arguments, context);
  copy<host_event_list_b_t, dev_event_list_b_t>(arguments, context);

  unsigned output_number_of_events = 0;

  // Copy all in a to the output container
  for (size_t i = 0; i < size<host_event_list_a_t>(arguments); ++i) {
    data<host_event_list_output_t>(arguments)[output_number_of_events] = data<host_event_list_a_t>(arguments)[i];
    ++output_number_of_events;
  }

  // Copy all in b that are not in a to the output container
  for (size_t j = 0; j < size<host_event_list_b_t>(arguments); ++j) {
    const auto element_b = data<host_event_list_b_t>(arguments)[j];
    bool unique = true;
    for (size_t i = 0; i < size<host_event_list_a_t>(arguments); ++i) {
      const auto element_a = data<host_event_list_a_t>(arguments)[i];
      if (element_a == element_b) {
        unique = false;
        break;
      }
    }
    if (unique) {
      data<host_event_list_output_t>(arguments)[output_number_of_events] = element_b;
      ++output_number_of_events;
    }
  }

  // Adjust the size of the output event lists
  reduce_size<host_event_list_output_t>(arguments, output_number_of_events);
  reduce_size<dev_event_list_output_t>(arguments, output_number_of_events);

  // Copy the event list to the device
  copy<dev_event_list_output_t, host_event_list_output_t>(arguments, context);

  if (property<verbosity_t>() >= logger::debug) {
    printf("List union:\n From lists:\n a: ");
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
