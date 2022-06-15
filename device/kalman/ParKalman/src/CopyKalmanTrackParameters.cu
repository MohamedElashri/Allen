
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CopyKalmanTrackParameters.cuh"
#include "CopyTrackParameters.cuh"

INSTANTIATE_ALGORITHM(copy_kalman_track_parameters::copy_kalman_track_parameters_t)


__global__ void create_kalman_tracks_for_checker(copy_kalman_track_parameters::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const auto event_long_tracks = parameters.dev_multi_event_long_tracks_view->container(event_number);
  const auto number_of_tracks_event = event_long_tracks.size();
  const auto offset_kalman_tracks = event_long_tracks.offset();
  const auto endvelo_states = parameters.dev_velo_states_view[event_number];
  Checker::Track* kalman_checker_tracks_event = parameters.dev_kalman_checker_tracks + offset_kalman_tracks;
  const ParKalmanFilter::FittedTrack* kf_tracks_event = parameters.dev_kf_tracks + offset_kalman_tracks;
  const PV::Vertex* rec_vertices_event =
    parameters.dev_multi_final_vertices + event_number * PatPV::max_number_vertices;

  const auto number_of_vertices_event = parameters.dev_number_of_multi_final_vertices[event_number];

  prepare_long_tracks(event_long_tracks, endvelo_states, kalman_checker_tracks_event);
  
  prepare_kalman_tracks(
    number_of_tracks_event, 
    number_of_vertices_event, 
    rec_vertices_event, 
    endvelo_states, 
    kf_tracks_event, 
    kalman_checker_tracks_event);
}

void copy_kalman_track_parameters::copy_kalman_track_parameters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_kalman_checker_tracks_t>(arguments, first<host_number_of_reconstructed_long_tracks_t>(arguments));
}

void copy_kalman_track_parameters::copy_kalman_track_parameters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(create_kalman_tracks_for_checker)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
}