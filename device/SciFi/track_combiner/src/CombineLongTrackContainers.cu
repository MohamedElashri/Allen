/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CombineLongTrackContainers.cuh"

INSTANTIATE_ALGORITHM(combine_long_track_containers::combine_long_track_containers_t)

__global__ void combine_track_offsets(combine_long_track_containers::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  for (unsigned event_number = threadIdx.x; event_number <= number_of_events; event_number += blockDim.x) {
    parameters.dev_offset_tracks_output[event_number] =
      parameters.dev_offset_tracks_0[event_number] + parameters.dev_offset_tracks_1[event_number];
  }
}

__global__ void combine_track_views(combine_long_track_containers::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;
  const auto event_tracks_offset_output = parameters.dev_offset_tracks_output[event_number];

  // Populate dev_long_track_view_output
  const auto number_of_tracks_0 =
    parameters.dev_offset_tracks_0[event_number + 1] - parameters.dev_offset_tracks_0[event_number];
  const auto event_tracks_offset_0 = parameters.dev_offset_tracks_0[event_number];
  for (unsigned track_index = threadIdx.x; track_index < number_of_tracks_0; track_index += blockDim.x) {
    parameters.dev_long_track_view_output[event_tracks_offset_output + track_index] =
      parameters.dev_long_track_view_0[event_tracks_offset_0 + track_index];

    parameters.dev_scifi_states_output[event_tracks_offset_output + track_index] =
      parameters.dev_scifi_states_0[event_tracks_offset_0 + track_index];
  }

  const auto number_of_tracks_1 =
    parameters.dev_offset_tracks_1[event_number + 1] - parameters.dev_offset_tracks_1[event_number];
  const auto event_tracks_offset_1 = parameters.dev_offset_tracks_1[event_number];
  for (unsigned track_index = threadIdx.x; track_index < number_of_tracks_1; track_index += blockDim.x) {
    parameters.dev_long_track_view_output[event_tracks_offset_output + number_of_tracks_0 + track_index] =
      parameters.dev_long_track_view_1[event_tracks_offset_1 + track_index];

    parameters.dev_scifi_states_output[event_tracks_offset_output + number_of_tracks_0 + track_index] =
      parameters.dev_scifi_states_1[event_tracks_offset_1 + track_index];
  }

  // Populate dev_long_tracks_view_output
  if (threadIdx.x == 0) {
    new (parameters.dev_long_tracks_view_output + event_number) Allen::Views::Physics::LongTracks {
      parameters.dev_long_track_view_output, parameters.dev_offset_tracks_output, event_number};
  }

  // Multi-event views
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_long_tracks_view_output)
      Allen::Views::Physics::MultiEventLongTracks {parameters.dev_long_tracks_view_output, number_of_events};
    parameters.dev_multi_event_long_tracks_ptr_output[0] = parameters.dev_multi_event_long_tracks_view_output.get();
  }
}

void combine_long_track_containers::combine_long_track_containers_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_long_track_view_output_t>(
    arguments, size<dev_long_track_view_0_t>(arguments) + size<dev_long_track_view_1_t>(arguments));
  set_size<dev_long_tracks_view_output_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_long_tracks_view_output_t>(arguments, 1);
  set_size<dev_multi_event_long_tracks_ptr_output_t>(arguments, 1);
  set_size<dev_offset_tracks_output_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_reconstructed_scifi_tracks_output_t>(arguments, 1);
  set_size<dev_scifi_states_output_t>(
    arguments, size<dev_scifi_states_0_t>(arguments) + size<dev_scifi_states_1_t>(arguments));
}

void combine_long_track_containers::combine_long_track_containers_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(combine_track_offsets)(1, 256, context)(arguments);

  global_function(combine_track_views)(first<host_number_of_events_t>(arguments), 256, context)(arguments);

  data<host_number_of_reconstructed_scifi_tracks_output_t>(arguments)[0] =
    first<host_number_of_reconstructed_scifi_tracks_0_t>(arguments) +
    first<host_number_of_reconstructed_scifi_tracks_1_t>(arguments);
}
