/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostLongValidator.h"

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
  std::vector<Checker::Tracks> tracks;
  tracks.resize(event_list.size());
  for (size_t i = 0; i < event_list.size(); ++i) {
    const auto evnum = event_list[i];
    const auto event_offset = event_tracks_offsets[evnum]; 
    const auto n_tracks = event_tracks_offsets[evnum+1] - event_offset; 
    std::vector<Checker::Track> sub = {long_tracks_for_checker.begin() + event_offset, long_tracks_for_checker.begin() + event_offset + n_tracks};
    tracks[i] = sub;
  }
     
  auto& checker =
    runtime_options.checker_invoker->checker<TrackCheckerLong>(name(), property<root_output_filename_t>());
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list);
}
