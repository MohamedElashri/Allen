/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PrepareTracks.h"
#include "ClusteringDefinitions.cuh"
#include "InputTools.h"
#include "MCParticle.h"
#include "SciFiConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "TrackChecker.h"
#include "CheckerTypes.h"
#include "UTConsolidated.cuh"
#include "UTDefinitions.cuh"
#include "VeloConsolidated.cuh"
#include "VeloEventModel.cuh"
#include "ROOTHeaders.h"
#include <random>

std::vector<Checker::Tracks> prepareVeloTracks(
  const unsigned* track_atomics,
  const unsigned* track_hit_number,
  const char* track_hits,
  const unsigned number_of_events,
  const unsigned event_list_size,
  const unsigned* event_list)
{
  /* Tracks to be checked, save in format for checker */
  std::vector<Checker::Tracks> checker_tracks(event_list_size); // all tracks from the selected events
  for (unsigned i = 0; i < event_list_size; i++) {
    const auto event_number = event_list[i];
    
    auto& tracks = checker_tracks[i]; // all tracks within one event

    Velo::Consolidated::ConstTracks velo_tracks {track_atomics, track_hit_number, event_number, number_of_events};
    const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);

    tracks.resize(number_of_tracks_event);

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      auto& t = tracks[i_track];
      t.p = 0.f;

      const auto velo_lhcb_ids = velo_tracks.get_lhcbids_for_track(track_hits, i_track);
      for (const auto id : velo_lhcb_ids) {
        t.addId(id);
      }
    } // tracks
  }

  return checker_tracks;
}

std::vector<Checker::Tracks> prepareUTTracks(
  const unsigned* velo_track_atomics,
  const unsigned* velo_track_hit_number,
  const char* velo_track_hits,
  const char* kalman_velo_states,
  const unsigned* ut_track_atomics,
  const unsigned* ut_track_hit_number,
  const char* ut_track_hits,
  const unsigned* ut_track_velo_indices,
  const float* ut_qop,
  const unsigned number_of_events,
  const unsigned event_list_size,
  const unsigned* event_list)
{
  std::vector<Checker::Tracks> checker_tracks; // all tracks from the selected events
  checker_tracks.reserve(event_list_size);
  for (unsigned i = 0; i < event_list_size; i++) {
    const auto event_number = event_list[i];

    Checker::Tracks tracks; // all tracks within one event

    Velo::Consolidated::ConstTracks velo_tracks {
      velo_track_atomics, velo_track_hit_number, event_number, number_of_events};
    Velo::Consolidated::ConstStates velo_states {kalman_velo_states, velo_tracks.total_number_of_tracks()};
    const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(event_number);
    UT::Consolidated::ConstExtendedTracks ut_tracks {
      ut_track_atomics, ut_track_hit_number, ut_qop, ut_track_velo_indices, event_number, number_of_events};
    const unsigned number_of_tracks_event = ut_tracks.number_of_tracks(event_number);

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      const int velo_track_index = ut_tracks.velo_track(i_track);
      const unsigned velo_state_index = velo_event_tracks_offset + velo_track_index;
      const VeloState velo_state = velo_states.get(velo_state_index);

      Checker::Track t;

      // momentum
      const float qop = ut_tracks.qop(i_track);
      t.p = 1.f / std::abs(qop);
      t.qop = qop;
      // direction at first state -> velo state of track
      const float tx = velo_state.tx;
      const float ty = velo_state.ty;
      const float slope2 = tx * tx + ty * ty;
      t.pt = std::sqrt(slope2 / (1.f + slope2)) / std::fabs(qop);
      // pseudorapidity
      const float rho = std::sqrt(slope2);
      t.eta = eta_from_rho(rho);

      // hits in UT
      const auto ut_lhcb_ids = ut_tracks.get_lhcbids_for_track(ut_track_hits, i_track);
      for (const auto id : ut_lhcb_ids) {
        t.addId(id);
      }
      // hits in Velo
      const auto velo_lhcb_ids = velo_tracks.get_lhcbids_for_track(velo_track_hits, velo_track_index);
      for (const auto id : velo_lhcb_ids) {
        t.addId(id);
      }
      tracks.push_back(t);
    } // tracks
    checker_tracks.emplace_back(tracks);
  }

  return checker_tracks;
}

std::vector<Checker::Tracks> prepareSciFiTracks(
  const unsigned* velo_track_atomics,
  const unsigned* velo_track_hit_number,
  const char* velo_track_hits,
  const char* kalman_velo_states,
  const unsigned* ut_track_atomics,
  const unsigned* ut_track_hit_number,
  const char* ut_track_hits,
  const unsigned* ut_track_velo_indices,
  const float* ut_qop,
  const unsigned* scifi_track_atomics,
  const unsigned* scifi_track_hit_number,
  const char* scifi_track_hits,
  const unsigned* scifi_track_ut_indices,
  const float* scifi_qop,
  const MiniState* scifi_states,
  const char* scifi_geometry,
  const std::array<float, 9>&,
  const float* muon_catboost_output,
  const bool* is_muon,
  const unsigned number_of_events,
  const unsigned event_list_size,
  const unsigned* event_list)
{
  const SciFi::SciFiGeometry scifi_geom(scifi_geometry);
  std::vector<Checker::Tracks> checker_tracks; // all tracks from the selected events
  int n_is_muon = 0;
  int n_total_tracks = 0;
  float n_hits_per_track_events = 0;

  checker_tracks.reserve(event_list_size);
  for (unsigned i = 0; i < event_list_size; i++) {
    const auto event_number = event_list[i];
    Checker::Tracks tracks; // all tracks within one event

    Velo::Consolidated::ConstTracks velo_tracks {
      velo_track_atomics, velo_track_hit_number, event_number, number_of_events};
    Velo::Consolidated::ConstStates velo_states {kalman_velo_states, velo_tracks.total_number_of_tracks()};
    const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(event_number);
    UT::Consolidated::ConstExtendedTracks ut_tracks {
      ut_track_atomics, ut_track_hit_number, ut_qop, ut_track_velo_indices, event_number, number_of_events};

    SciFi::Consolidated::ConstTracks scifi_tracks {scifi_track_atomics,
                                                   scifi_track_hit_number,
                                                   scifi_qop,
                                                   scifi_states,
                                                   scifi_track_ut_indices,
                                                   event_number,
                                                   number_of_events};
    const unsigned number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
    const unsigned event_offset = scifi_tracks.tracks_offset(event_number);

    float n_hits_per_track = 0;

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      const auto ut_track_index = scifi_tracks.ut_track(i_track);
      const auto velo_track_index = ut_tracks.velo_track(ut_track_index);
      const auto velo_state_index = velo_event_tracks_offset + velo_track_index;
      const auto velo_state = velo_states.get(velo_state_index);

      Checker::Track t;

      // momentum
      const float qop = scifi_tracks.qop(i_track);
      t.p = 1.f / std::abs(qop);
      t.qop = qop;
      // direction at first state -> velo state of track
      const float tx = velo_state.tx;
      const float ty = velo_state.ty;
      const float slope2 = tx * tx + ty * ty;
      t.pt = std::sqrt(slope2 / (1.f + slope2)) / std::fabs(qop);
      // pseudorapidity
      const float rho = std::sqrt(slope2);
      t.eta = eta_from_rho(rho);

      // add SciFi hits
      const auto scifi_lhcb_ids = scifi_tracks.get_lhcbids_for_track(scifi_track_hits, i_track);
      for (const auto id : scifi_lhcb_ids) {
        t.addId(id);
      }

      n_hits_per_track += scifi_tracks.number_of_hits(i_track);

      // add UT hits
      const auto ut_lhcb_ids = ut_tracks.get_lhcbids_for_track(ut_track_hits, ut_track_index);
      for (const auto id : ut_lhcb_ids) {
        t.addId(id);
      }

      // add Velo hits
      const auto velo_lhcb_ids = velo_tracks.get_lhcbids_for_track(velo_track_hits, velo_track_index);
      for (const auto id : velo_lhcb_ids) {
        t.addId(id);
      }

      // add muon information
      t.muon_catboost_output = muon_catboost_output[event_offset + i_track];
      t.is_muon = is_muon[event_offset + i_track];

      if (t.is_muon) n_is_muon++;

      n_total_tracks++;

      tracks.push_back(t);
    } // tracks
    if (number_of_tracks_event > 0) {
      n_hits_per_track /= number_of_tracks_event;
      n_hits_per_track_events += n_hits_per_track;
    }

    checker_tracks.emplace_back(tracks);
  }
  if (number_of_events > 0) {
    n_hits_per_track_events /= number_of_events;
    debug_cout << "Average number of hits on SciFi segment of tracks = " << n_hits_per_track_events << std::endl;
  }

  debug_cout << "Number of tracks with is_muon true = " << n_is_muon << " / " << n_total_tracks << std::endl;

  return checker_tracks;
}
