/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostForwardValidator.h"
#include "PrepareTracks.h"

void host_forward_validator::host_forward_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context&) const
{
  const auto offsets_all_velo_tracks = make_vector<dev_offsets_all_velo_tracks_t>(arguments);
  const auto offsets_velo_track_hit_number = make_vector<dev_offsets_velo_track_hit_number_t>(arguments);
  const auto velo_track_hits = make_vector<dev_velo_track_hits_t>(arguments);
  const auto event_list = make_vector<dev_event_list_t>(arguments);
  const auto velo_kalman_endvelo_states = make_vector<dev_velo_kalman_endvelo_states_t>(arguments);
  const auto offsets_ut_tracks = make_vector<dev_offsets_ut_tracks_t>(arguments);
  const auto offsets_ut_track_hit_number = make_vector<dev_offsets_ut_track_hit_number_t>(arguments);
  const auto ut_track_hits = make_vector<dev_ut_track_hits_t>(arguments);
  const auto ut_track_velo_indices = make_vector<dev_ut_track_velo_indices_t>(arguments);
  const auto ut_qop = make_vector<dev_ut_qop_t>(arguments);
  const auto offsets_forward_tracks = make_vector<dev_offsets_forward_tracks_t>(arguments);
  const auto offsets_scifi_track_hit_number = make_vector<dev_offsets_scifi_track_hit_number_t>(arguments);
  const auto scifi_track_hits = make_vector<dev_scifi_track_hits_t>(arguments);
  const auto scifi_track_ut_indices = make_vector<dev_scifi_track_ut_indices_t>(arguments);
  const auto scifi_qop = make_vector<dev_scifi_qop_t>(arguments);
  const auto scifi_states = make_vector<dev_scifi_states_t>(arguments);

  const auto tracks = prepareForwardTracks(
    first<host_number_of_events_t>(arguments),
    offsets_all_velo_tracks,
    offsets_velo_track_hit_number,
    velo_track_hits,
    velo_kalman_endvelo_states,
    offsets_ut_tracks,
    offsets_ut_track_hit_number,
    ut_track_hits,
    ut_track_velo_indices,
    ut_qop,
    offsets_forward_tracks,
    offsets_scifi_track_hit_number,
    scifi_track_hits,
    scifi_track_ut_indices,
    scifi_qop,
    scifi_states,
    constants.host_scifi_geometry.data(),
    event_list);

  auto& checker =
    runtime_options.checker_invoker->checker<TrackCheckerForward>(name(), property<root_output_filename_t>());
  checker.accumulate(first<host_mc_events_t>(arguments), tracks, event_list);
}
