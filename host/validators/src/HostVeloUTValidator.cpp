/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostVeloUTValidator.h"
#include "PrepareTracks.h"

INSTANTIATE_ALGORITHM(host_velo_ut_validator::host_velo_ut_validator_t)

void host_velo_ut_validator::host_velo_ut_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  const auto offsets_all_velo_tracks = make_host_buffer<dev_offsets_all_velo_tracks_t>(arguments, context);
  const auto offsets_velo_track_hit_number = make_host_buffer<dev_offsets_velo_track_hit_number_t>(arguments, context);
  const auto velo_track_hits = make_host_buffer<dev_velo_track_hits_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);
  const auto velo_kalman_endvelo_states = make_host_buffer<dev_velo_kalman_endvelo_states_t>(arguments, context);
  const auto offsets_ut_tracks = make_host_buffer<dev_offsets_ut_tracks_t>(arguments, context);
  const auto offsets_ut_track_hit_number = make_host_buffer<dev_offsets_ut_track_hit_number_t>(arguments, context);
  const auto ut_track_hits = make_host_buffer<dev_ut_track_hits_t>(arguments, context);
  const auto ut_track_velo_indices = make_host_buffer<dev_ut_track_velo_indices_t>(arguments, context);
  const auto ut_qop = make_host_buffer<dev_ut_qop_t>(arguments, context);

  auto tracks = prepareUTTracks(
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

  auto& checker =
    runtime_options.checker_invoker->checker<TrackCheckerVeloUT>(name(), property<root_output_filename_t>());
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list);
}
