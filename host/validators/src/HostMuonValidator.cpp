/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostMuonValidator.h"
#include "PrepareTracks.h"
#include <ROOTHeaders.h>

INSTANTIATE_ALGORITHM(host_muon_validator::host_muon_validator_t)

void host_muon_validator::host_muon_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context&) const
{
  const auto event_list = make_vector<dev_event_list_t>(arguments);
  const auto long_tracks_for_checker = make_vector<dev_long_checker_tracks_t>(arguments); 
  const auto event_tracks_offsets = make_vector<dev_offsets_long_tracks_t>(arguments); 
  const auto is_muon = make_vector<dev_is_muon_t>(arguments);

  const auto tracks = prepareLongTracks(
    first<host_number_of_events_t>(arguments),
    long_tracks_for_checker, 
    event_tracks_offsets,
    event_list,
    is_muon);

  auto& checker =
    runtime_options.checker_invoker->checker<TrackCheckerMuon>(name(), property<root_output_filename_t>());
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list);
}
