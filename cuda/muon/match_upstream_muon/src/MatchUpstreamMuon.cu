#include "MatchUpstreamMuon.cuh"

__global__ void MatchUpstreamMuon::match_upstream_muon(
  MatchUpstreamMuon::Parameters parameters,
  const float* magnet_polarity,
  const MatchUpstreamMuon::MuonChambers* dev_muonmatch_search_muon_chambers,
  const MatchUpstreamMuon::SearchWindows* dev_muonmatch_search_windows,
  const uint number_of_events)
{

  const uint i_event = parameters.dev_event_list_mf[blockIdx.x];

  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, i_event, number_of_events};

  Velo::Consolidated::ConstKalmanStates velo_states {parameters.dev_kalmanvelo_states,
                                                     velo_tracks.total_number_of_tracks()};

  UT::Consolidated::ConstExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                                   parameters.dev_ut_track_hit_number,
                                                   parameters.dev_ut_qop,
                                                   parameters.dev_ut_track_velo_indices,
                                                   i_event,
                                                   number_of_events};

  for (uint i_uttrack = threadIdx.x; i_uttrack < ut_tracks.number_of_tracks(i_event); i_uttrack += blockDim.x) {

    const uint i_velo_track = ut_tracks.velo_track(i_uttrack);
    const uint velo_states_index = velo_tracks.tracks_offset(i_event) + i_velo_track;
    const KalmanVeloState velo_state = velo_states.get(velo_states_index);
    const uint absolute_index_ut = ut_tracks.tracks_offset(i_event) + i_uttrack;

    const bool matched = match(
      ut_tracks.qop(i_uttrack),
      velo_state,
      parameters.dev_muon_hits[i_event],
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