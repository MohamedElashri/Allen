#include "EventListIntersection.cuh"

void event_list_intersection::event_list_intersection_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
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
  HostBuffers&,
  const Allen::Context& context) const
{
  copy<host_event_list_a_t, dev_event_list_a_t>(arguments, context);
  copy<host_event_list_b_t, dev_event_list_b_t>(arguments, context);

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
  copy<dev_event_list_output_t, host_event_list_output_t>(arguments, context);

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
