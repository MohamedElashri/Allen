/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PrepareKalmanTracks.h"

std::vector<Checker::Tracks> prepareKalmanTracks(
  const unsigned number_of_events,
  gsl::span<const SciFi::KalmanCheckerTrack> kalman_checker_tracks,
  gsl::span<const unsigned> event_tracks_offsets,
  gsl::span<const mask_t> event_list)
{
  std::vector<Checker::Tracks> checker_tracks(number_of_events);
  // Loop over events.
  for (unsigned i_evlist = 0; i_evlist < event_list.size(); i_evlist++) {
    const auto i_event = event_list[i_evlist];
    auto& tracks = checker_tracks[i_event];

    // Make the long tracks.
    const auto number_of_tracks_event = event_tracks_offsets[i_event + 1] - event_tracks_offsets[i_event];
    const auto event_offset = event_tracks_offsets[i_event];
    const SciFi::KalmanCheckerTrack* event_kalman_tracks = kalman_checker_tracks.data() + event_offset;
    tracks.resize(number_of_tracks_event);

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      auto& t = tracks[i_track];

      const auto kalman_track = event_kalman_tracks[i_track];

      // add all hits
      const auto total_number_of_hits = kalman_track.total_number_of_hits;
      for (unsigned int ihit = 0; ihit < total_number_of_hits; ihit++) {
        const auto id = kalman_track.allids[ihit];
        t.addId(id);
      }
      t.velo_ip = kalman_track.velo_ip;
      t.velo_ip_chi2 = kalman_track.velo_ip_chi2;
      t.velo_ipx = kalman_track.velo_ipx;
      t.velo_ipy = kalman_track.velo_ipy;
      t.velo_docaz = kalman_track.velo_docaz;
      t.kalman_ip = kalman_track.kalman_ip;
      t.kalman_ip_chi2 = kalman_track.kalman_ip_chi2;
      t.kalman_ipx = kalman_track.kalman_ipx;
      t.kalman_ipy = kalman_track.kalman_ipy;
      t.kalman_docaz = kalman_track.kalman_docaz;
      t.z = kalman_track.z;
      t.x = kalman_track.x;
      t.y = kalman_track.y;
      t.tx = kalman_track.tx;
      t.ty = kalman_track.ty;
      t.qop = kalman_track.qop;
      t.chi2 = kalman_track.chi2;
      t.chi2V = kalman_track.chi2V;
      t.chi2T = kalman_track.chi2T;
      t.ndof = kalman_track.ndof;
      t.ndofV = kalman_track.ndofV;
      t.ndofT = kalman_track.ndofT;
      t.first_qop = kalman_track.first_qop;
      t.best_qop = kalman_track.best_qop;
      t.p = kalman_track.p;
      t.pt = kalman_track.pt;

    } // Track loop.
  }   // Event loop.

  return checker_tracks;
}
