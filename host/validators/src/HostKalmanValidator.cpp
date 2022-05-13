/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostKalmanValidator.h"
#include "PrepareKalmanTracks.h"
#include "KalmanChecker.h"

INSTANTIATE_ALGORITHM(host_kalman_validator::host_kalman_validator_t)

void host_kalman_validator::host_kalman_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context&) const
{
  const auto event_list = make_vector<dev_event_list_t>(arguments);
  const auto multi_event_long_tracks_view = make_vector<dev_multi_event_long_tracks_view_t>(arguments);
  const auto velo_kalman_states = make_vector<dev_velo_states_view_t>(arguments);
  const auto kf_tracks = make_vector<dev_kf_tracks_t>(arguments);
  const auto multi_final_vertices = make_vector<dev_multi_final_vertices_t>(arguments);
  const auto number_of_multi_final_vertices = make_vector<dev_number_of_multi_final_vertices_t>(arguments);

  const auto tracks = prepareKalmanTracks(
    first<host_number_of_events_t>(arguments),
    multi_event_long_tracks_view,
    velo_kalman_states,
    constants.host_scifi_geometry.data(),
    kf_tracks,
    multi_final_vertices,
    number_of_multi_final_vertices,
    event_list);

  auto& checker =
    runtime_options.checker_invoker->checker<KalmanChecker>(name(), property<root_output_filename_t>(), false);
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list);
}
