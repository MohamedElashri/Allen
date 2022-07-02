
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "KalmanValidator.cuh"
#include "CopyTrackParameters.cuh"

INSTANTIATE_ALGORITHM(kalman_validator::kalman_validator_t)

__global__ void create_kalman_tracks_for_checker(kalman_validator::Parameters parameters)
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

void kalman_validator::kalman_validator_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_kalman_checker_tracks_t>(arguments, first<host_number_of_reconstructed_long_tracks_t>(arguments));
}

void kalman_validator::kalman_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(create_kalman_tracks_for_checker)(first<host_number_of_events_t>(arguments), 256, context)(arguments);

  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);
  const auto kalman_tracks_for_checker = make_host_buffer<dev_kalman_checker_tracks_t>(arguments, context);
  const auto event_tracks_offsets = make_host_buffer<dev_offsets_long_tracks_t>(arguments, context);
  std::vector<std::vector<Checker::Track>> tracks;
  tracks.resize(event_list.size());
  for (size_t i = 0; i < event_list.size(); ++i) {
    const auto evnum = event_list[i];
    const auto event_offset = event_tracks_offsets[evnum];
    const auto n_tracks = event_tracks_offsets[evnum + 1] - event_offset;
    std::vector<Checker::Track> event_trakcs = {kalman_tracks_for_checker.begin() + event_offset,
                                                kalman_tracks_for_checker.begin() + event_offset + n_tracks};
    tracks[i] = event_trakcs;
  }

  auto& checker =
    runtime_options.checker_invoker->checker<KalmanChecker>(name(), property<root_output_filename_t>(), false);
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list);
}