/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "MatchUpstreamMuon.cuh"

void MatchUpstreamMuon::match_upstream_muon_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_match_upstream_muon_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
}

void MatchUpstreamMuon::match_upstream_muon_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  initialize<dev_match_upstream_muon_t>(arguments, 0, context);

  global_function(match_upstream_muon)(
    dim3(first<host_selected_events_mf_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_magnet_polarity.data(),
    constants.dev_muonmatch_search_muon_chambers,
    constants.dev_muonmatch_search_windows,
    first<host_number_of_events_t>(arguments));

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_match_upstream_muon_t>(host_buffers.host_match_upstream_muon, arguments, context);
  }
}

__global__ void MatchUpstreamMuon::match_upstream_muon(
  MatchUpstreamMuon::Parameters parameters,
  const float* magnet_polarity,
  const MatchUpstreamMuon::MuonChambers* dev_muonmatch_search_muon_chambers,
  const MatchUpstreamMuon::SearchWindows* dev_muonmatch_search_windows,
  const unsigned number_of_events)
{
  const unsigned i_event = parameters.dev_event_list_mf[blockIdx.x];

  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, i_event, number_of_events};

  Velo::Consolidated::ConstStates velo_states {parameters.dev_kalmanvelo_states, velo_tracks.total_number_of_tracks()};

  UT::Consolidated::ConstExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                                   parameters.dev_ut_track_hit_number,
                                                   parameters.dev_ut_qop,
                                                   parameters.dev_ut_track_velo_indices,
                                                   i_event,
                                                   number_of_events};

  const auto muon_total_number_of_hits =
    parameters.dev_station_ocurrences_offset[number_of_events * Muon::Constants::n_stations];
  const auto station_ocurrences_offset =
    parameters.dev_station_ocurrences_offset + i_event * Muon::Constants::n_stations;
  const auto muon_hits = Muon::ConstHits {parameters.dev_muon_hits, muon_total_number_of_hits};

  for (unsigned i_uttrack = threadIdx.x; i_uttrack < ut_tracks.number_of_tracks(i_event); i_uttrack += blockDim.x) {

    const unsigned i_velo_track = ut_tracks.velo_track(i_uttrack);
    const unsigned velo_states_index = velo_tracks.tracks_offset(i_event) + i_velo_track;
    const KalmanVeloState velo_state = velo_states.get_kalman_state(velo_states_index);
    const unsigned absolute_index_ut = ut_tracks.tracks_offset(i_event) + i_uttrack;

    const bool matched = match(
      ut_tracks.qop(i_uttrack),
      velo_state,
      station_ocurrences_offset,
      muon_hits,
      magnet_polarity,
      dev_muonmatch_search_muon_chambers[0],
      dev_muonmatch_search_windows[0]);
    if (matched) {
      parameters.dev_muon_match[absolute_index_ut] = true;
    }
    else {
      parameters.dev_muon_match[absolute_index_ut] = false;
    }
  }
}