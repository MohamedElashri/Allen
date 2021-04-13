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
  const unsigned number_of_events,
  gsl::span<const unsigned> track_atomics,
  gsl::span<const unsigned> track_hit_number,
  gsl::span<const char> track_hits,
  gsl::span<const mask_t> event_list)
{
  /* Tracks to be checked, save in format for checker */
  std::vector<Checker::Tracks> checker_tracks(event_list.size());
  for (unsigned i = 0; i < event_list.size(); i++) {
    const auto event_number = event_list[i];

    // Tracks of this event
    auto& tracks = checker_tracks[i];

    Velo::Consolidated::ConstTracks velo_tracks {
      track_atomics.data(), track_hit_number.data(), event_number, number_of_events};
    const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
    tracks.resize(number_of_tracks_event);

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      auto& t = tracks[i_track];
      t.p = 0.f;

      const auto velo_lhcb_ids = velo_tracks.get_lhcbids_for_track(track_hits.data(), i_track);
      for (const auto id : velo_lhcb_ids) {
        t.addId(id);
      }
    } // tracks
  }

  return checker_tracks;
}

std::vector<Checker::Tracks> prepareUTTracks(
  const unsigned number_of_events,
  gsl::span<const unsigned> velo_track_atomics,
  gsl::span<const unsigned> velo_track_hit_number,
  gsl::span<const char> velo_track_hits,
  gsl::span<const char> kalman_velo_states,
  gsl::span<const unsigned> ut_track_atomics,
  gsl::span<const unsigned> ut_track_hit_number,
  gsl::span<const char> ut_track_hits,
  gsl::span<const unsigned> ut_track_velo_indices,
  gsl::span<const float> ut_qop,
  gsl::span<const mask_t> event_list)
{
  std::vector<Checker::Tracks> checker_tracks(event_list.size());
  for (unsigned i = 0; i < event_list.size(); i++) {
    const auto event_number = event_list[i];

    // Tracks of this event
    auto& tracks = checker_tracks[i];

    Velo::Consolidated::ConstTracks velo_tracks {
      velo_track_atomics.data(), velo_track_hit_number.data(), event_number, number_of_events};
    Velo::Consolidated::ConstStates velo_states {kalman_velo_states.data(), velo_tracks.total_number_of_tracks()};
    const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(event_number);
    UT::Consolidated::ConstExtendedTracks ut_tracks {ut_track_atomics.data(),
                                                     ut_track_hit_number.data(),
                                                     ut_qop.data(),
                                                     ut_track_velo_indices.data(),
                                                     event_number,
                                                     number_of_events};
    const unsigned number_of_tracks_event = ut_tracks.number_of_tracks(event_number);
    tracks.resize(number_of_tracks_event);

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      const int velo_track_index = ut_tracks.velo_track(i_track);
      const unsigned velo_state_index = velo_event_tracks_offset + velo_track_index;
      const auto velo_state = velo_states.get(velo_state_index);
      auto& t = tracks[i_track];

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
      const auto ut_lhcb_ids = ut_tracks.get_lhcbids_for_track(ut_track_hits.data(), i_track);
      for (const auto id : ut_lhcb_ids) {
        t.addId(id);
      }
      // hits in Velo
      const auto velo_lhcb_ids = velo_tracks.get_lhcbids_for_track(velo_track_hits.data(), velo_track_index);
      for (const auto id : velo_lhcb_ids) {
        t.addId(id);
      }
    } // tracks
  }

  return checker_tracks;
}

std::vector<Checker::Tracks> prepareForwardTracks(
  const unsigned number_of_events,
  gsl::span<const unsigned> velo_track_atomics,
  gsl::span<const unsigned> velo_track_hit_number,
  gsl::span<const char> velo_track_hits,
  gsl::span<const char> kalman_velo_states,
  gsl::span<const unsigned> ut_track_atomics,
  gsl::span<const unsigned> ut_track_hit_number,
  gsl::span<const char> ut_track_hits,
  gsl::span<const unsigned> ut_track_velo_indices,
  gsl::span<const float> ut_qop,
  gsl::span<const unsigned> scifi_track_atomics,
  gsl::span<const unsigned> scifi_track_hit_number,
  gsl::span<const char> scifi_track_hits,
  gsl::span<const unsigned> scifi_track_ut_indices,
  gsl::span<const float> scifi_qop,
  gsl::span<const MiniState> scifi_states,
  const char* scifi_geometry,
  gsl::span<const mask_t> event_list,
  gsl::span<const Allen::bool_as_char_t<bool>> is_muon)
{
  const SciFi::SciFiGeometry scifi_geom(scifi_geometry);
  std::vector<Checker::Tracks> checker_tracks(event_list.size());
  float n_hits_per_track_events = 0;

  for (unsigned i = 0; i < event_list.size(); i++) {
    const auto event_number = event_list[i];

    // Tracks of this event
    auto& tracks = checker_tracks[i];

    Velo::Consolidated::ConstTracks velo_tracks {
      velo_track_atomics.data(), velo_track_hit_number.data(), event_number, number_of_events};
    Velo::Consolidated::ConstStates velo_states {kalman_velo_states.data(), velo_tracks.total_number_of_tracks()};
    const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(event_number);
    UT::Consolidated::ConstExtendedTracks ut_tracks {ut_track_atomics.data(),
                                                     ut_track_hit_number.data(),
                                                     ut_qop.data(),
                                                     ut_track_velo_indices.data(),
                                                     event_number,
                                                     number_of_events};

    SciFi::Consolidated::ConstTracks scifi_tracks {scifi_track_atomics.data(),
                                                   scifi_track_hit_number.data(),
                                                   scifi_qop.data(),
                                                   scifi_states.data(),
                                                   scifi_track_ut_indices.data(),
                                                   event_number,
                                                   number_of_events};

    const unsigned number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
    const unsigned event_offset = scifi_tracks.tracks_offset(event_number);
    tracks.resize(number_of_tracks_event);

    float n_hits_per_track = 0;

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      const auto ut_track_index = scifi_tracks.ut_track(i_track);
      const auto velo_track_index = ut_tracks.velo_track(ut_track_index);
      const auto velo_state_index = velo_event_tracks_offset + velo_track_index;
      const auto velo_state = velo_states.get(velo_state_index);

      auto& t = tracks[i_track];

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
      const auto scifi_lhcb_ids = scifi_tracks.get_lhcbids_for_track(scifi_track_hits.data(), i_track);
      for (const auto id : scifi_lhcb_ids) {
        t.addId(id);
      }

      n_hits_per_track += scifi_tracks.number_of_hits(i_track);

      // add UT hits
      const auto ut_lhcb_ids = ut_tracks.get_lhcbids_for_track(ut_track_hits.data(), ut_track_index);
      for (const auto id : ut_lhcb_ids) {
        t.addId(id);
      }

      // add Velo hits
      const auto velo_lhcb_ids = velo_tracks.get_lhcbids_for_track(velo_track_hits.data(), velo_track_index);
      for (const auto id : velo_lhcb_ids) {
        t.addId(id);
      }

      if (is_muon.size()) {
        t.is_muon = is_muon[event_offset + i_track];
      }
    } // tracks

    if (number_of_tracks_event > 0) {
      n_hits_per_track /= number_of_tracks_event;
      n_hits_per_track_events += n_hits_per_track;
    }
  }

  if (number_of_events > 0) {
    n_hits_per_track_events /= number_of_events;
    debug_cout << "Average number of hits on SciFi segment of tracks = " << n_hits_per_track_events << std::endl;
  }

  return checker_tracks;
}
