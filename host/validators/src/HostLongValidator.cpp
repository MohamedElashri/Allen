/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostLongValidator.h"
#include "PrepareTracks.h"

INSTANTIATE_ALGORITHM(host_long_validator::host_long_validator_t)

void host_long_validator::host_long_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  const auto event_list = make_vector<dev_event_list_t>(arguments);
  const auto long_tracks_for_checker = make_vector<dev_long_checker_tracks_t>(arguments);
  const auto event_tracks_offsets = make_vector<dev_offsets_long_tracks_t>(arguments);
  const auto tracks = prepareLongTracks(
    first<host_number_of_events_t>(arguments), long_tracks_for_checker, event_tracks_offsets, event_list);

  auto& checker =
    runtime_options.checker_invoker->checker<TrackCheckerLong>(name(), property<root_output_filename_t>());
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list);
}
