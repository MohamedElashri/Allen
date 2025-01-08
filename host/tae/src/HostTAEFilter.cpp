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
#include "HostTAEFilter.h"
#include <optional>

INSTANTIATE_ALGORITHM(host_tae_filter::host_tae_filter_t)

void tae_filter(
  host_tae_filter::host_tae_filter_t::Parameters parameters,
  unsigned const number_of_events,
  bool const accept_sub_events)
{
  unsigned n_tae = 0;
  unsigned event_list_size = 0;
  auto event_list_start = parameters.host_mask_event_list.data();
  auto const event_list_end = parameters.host_mask_event_list.data() + parameters.host_mask_event_list.size();
  for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
    auto event_number = parameters.host_event_list[event_index];
    LHCb::ODIN odin {parameters.host_odin_data[event_number]};

    // Once the start of the TAE group is found, look for the rest
    if (odin.timeAlignmentEventFirst()) {
      unsigned tae_start = event_number;
      std::optional<unsigned> tae_window;
      unsigned prev_event = event_number;

      // Loop until an non-TAE event or the end of the batch is encountered
      for (++event_number; event_number < number_of_events; ++event_number) {
        odin = LHCb::ODIN {parameters.host_odin_data[event_number]};

        if (!odin.isTAE()) {
          break;
        }
        else if (event_number - prev_event > 1) {
          break;
        }
        else if (odin.timeAlignmentEventCentral()) {
          // check wether the central event is within the activity mask
          auto central_tae_in_event_list = std::find(event_list_start, event_list_end, event_number);
          if (central_tae_in_event_list == event_list_end) { // central TAE event not in input event list
            break;
          }
          else {
            event_list_start = central_tae_in_event_list; // update start of search to the one that has been found
          }
          tae_window = event_number - tae_start;
        }
        else if (tae_window && (event_number == tae_start + 2 * *tae_window)) {
          // fill the event list only once the last event in the tae group is found,

          if (accept_sub_events) {
            // sub events should be output as separate events
            for (unsigned tae_event = tae_start; tae_event <= event_number; ++tae_event) {
              parameters.host_output_event_list[event_list_size++] = tae_event;
            }
          }
          else {
            // sub events should be output as part of a TAE event, so only accept the central event
            parameters.host_output_event_list[event_list_size++] = tae_start + *tae_window;
            parameters.host_tae_events[n_tae++] = TAE::TAEEvent {tae_start + *tae_window, *tae_window};
          }
          break;
        }
        prev_event = event_number;
      }
    }
  }
  parameters.host_number_of_tae_events[0] = n_tae;
  parameters.host_number_of_selected_events[0] = event_list_size;
}

void host_tae_filter::host_tae_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const n_events =
    size<host_event_list_t>(arguments); // this is not the full mask, it is only the event list from ODIN

  set_size<host_number_of_tae_events_t>(arguments, 1);
  set_size<host_tae_events_t>(arguments, m_accept_sub_events.value() ? 0 : TAE::max_tae_events(n_events));
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<host_output_event_list_t>(arguments, n_events);
  set_size<host_mask_event_list_t>(arguments, size<dev_event_list_t>(arguments));
  set_size<dev_event_output_list_t>(arguments, n_events);
}

void host_tae_filter::host_tae_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset<host_output_event_list_t>(arguments, 0, context);
  Allen::memset<host_tae_events_t>(arguments, TAE::TAEEvent {}, context);

  auto n_mask = size<dev_event_list_t>(arguments);
  Allen::copy(
    get<host_mask_event_list_t>(arguments),
    get<dev_event_list_t>(arguments),
    context,
    Allen::memcpyDeviceToHost,
    n_mask);

  host_function(tae_filter)(arguments, size<host_event_list_t>(arguments), m_accept_sub_events.value());

  auto n_selected = first<host_number_of_selected_events_t>(arguments);
  reduce_size<host_tae_events_t>(arguments, first<host_number_of_tae_events_t>(arguments));
  reduce_size<host_output_event_list_t>(arguments, n_selected);
  reduce_size<dev_event_output_list_t>(arguments, first<host_number_of_selected_events_t>(arguments));
  Allen::copy(
    get<dev_event_output_list_t>(arguments),
    get<host_output_event_list_t>(arguments),
    context,
    Allen::memcpyHostToDevice,
    n_selected);
}
