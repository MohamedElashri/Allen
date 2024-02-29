/************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\************************************************************************/
#include "LongTrackActivity.cuh"

INSTANTIATE_ALGORITHM(long_track_activity_filter::long_track_activity_filter_t)

void long_track_activity_filter::long_track_activity_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{

  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void long_track_activity_filter::long_track_activity_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{

  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(long_track_activity_filter)(dim3(1), dim3(property<block_dim_x_t>().get()), context)(
    arguments, size<dev_event_list_t>(arguments));
  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void long_track_activity_filter::long_track_activity_filter(
  long_track_activity_filter::Parameters parameters,
  const unsigned number_of_selected_events)
{

  for (unsigned idx = threadIdx.x; idx < number_of_selected_events; idx += blockDim.x) {
    auto event_number = parameters.dev_event_list[idx];

    const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);
    const unsigned number_of_long_tracks = long_tracks.size();

    if (number_of_long_tracks >= parameters.min_long_tracks && number_of_long_tracks < parameters.max_long_tracks) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}
