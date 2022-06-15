/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CopyLongTrackParameters.cuh"
#include "CopyTrackParameters.cuh"

INSTANTIATE_ALGORITHM(copy_long_track_parameters::copy_long_track_parameters_t)

__global__ void copy_long_track_parameters::copy_long_track_parameters(copy_long_track_parameters::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const auto event_long_tracks = parameters.dev_multi_event_long_tracks_view->container(event_number);
  const auto endvelo_states = parameters.dev_velo_states_view[event_number];
  const unsigned offset_long_tracks = event_long_tracks.offset();
  Checker::Track* long_checker_tracks_event = parameters.dev_long_checker_tracks + offset_long_tracks;

  prepare_long_tracks(event_long_tracks, endvelo_states, long_checker_tracks_event);
}

void copy_long_track_parameters::copy_long_track_parameters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_long_checker_tracks_t>(arguments, first<host_number_of_reconstructed_long_tracks_t>(arguments));
}

void copy_long_track_parameters::copy_long_track_parameters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(copy_long_track_parameters)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
}