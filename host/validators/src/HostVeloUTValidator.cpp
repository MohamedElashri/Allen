/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostVeloUTValidator.h"
#include "PrepareTracks.h"

void host_velo_ut_validator::host_velo_ut_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
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

  const auto tracks = prepareUTTracks(
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
    event_list);

  auto& checker = runtime_options.checker_invoker->checker<TrackCheckerVeloUT>(name(), property<root_output_filename_t>());
  checker.accumulate(first<host_mc_events_t>(arguments), tracks, event_list);
}
