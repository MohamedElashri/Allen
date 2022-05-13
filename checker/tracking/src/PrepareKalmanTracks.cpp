/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PrepareKalmanTracks.h"

float ipKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float tx = track.state[2];
  float ty = track.state[3];
  float dz = vertex.position.z - track.z;
  float dx = track.state[0] + dz * tx - vertex.position.x;
  float dy = track.state[1] + dz * ty - vertex.position.y;
  return std::sqrt((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

float ipxKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float tx = track.state[2];
  float dz = vertex.position.z - track.z;
  float dx = track.state[0] + dz * tx - vertex.position.x;
  return dx;
}

float ipyKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float ty = track.state[3];
  float dz = vertex.position.z - track.z;
  float dy = track.state[1] + dz * ty - vertex.position.y;
  return dy;
}

float ipChi2Kalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float tx = track.state[2];
  float ty = track.state[3];
  float dz = vertex.position.z - track.z;
  float dx = track.state[0] + dz * tx - vertex.position.x;
  float dy = track.state[1] + dz * ty - vertex.position.y;

  // Build covariance matrix.
  float cov00 = vertex.cov00 + track.cov(0, 0);
  float cov10 = vertex.cov10;
  float cov11 = vertex.cov11 + track.cov(1, 1);

  // Add contribution from extrapolation.
  cov00 += dz * dz * track.cov(2, 2) + 2 * std::abs(dz * track.cov(2, 0));
  cov11 += dz * dz * track.cov(3, 3) + 2 * dz * track.cov(3, 1);

  // Add the contribution from the PV z position.
  cov00 += tx * tx * vertex.cov22 - 2 * tx * vertex.cov20;
  cov10 += tx * ty * vertex.cov22 - ty * vertex.cov20 - tx * vertex.cov21;
  cov11 += ty * ty * vertex.cov22 - 2 * ty * vertex.cov21;

  // Invert the covariance matrix.
  float D = cov00 * cov11 - cov10 * cov10;
  float invcov00 = cov11 / D;
  float invcov10 = -cov10 / D;
  float invcov11 = cov00 / D;

  return dx * dx * invcov00 + 2 * dx * dy * invcov10 + dy * dy * invcov11;
}

float kalmanDOCAz(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  float dx = track.state[0] - vertex.position.x;
  float dy = track.state[1] - vertex.position.y;
  float tx = track.state[2];
  float ty = track.state[3];
  return std::abs(ty * dx - tx * dy) / std::sqrt(tx * tx + ty * ty);
}

float ipVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_state.tx();
  float ty = velo_kalman_state.ty();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dx = velo_kalman_state.x() + dz * tx - vertex.position.x;
  float dy = velo_kalman_state.y() + dz * ty - vertex.position.y;
  return std::sqrt((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

float ipxVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_state.tx();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dx = velo_kalman_state.x() + dz * tx - vertex.position.x;
  return dx;
}

float ipyVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float ty = velo_kalman_state.ty();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dy = velo_kalman_state.y() + dz * ty - vertex.position.y;
  return dy;
}

float ipChi2Velo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_state.tx();
  float ty = velo_kalman_state.ty();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dx = velo_kalman_state.x() + dz * tx - vertex.position.x;
  float dy = velo_kalman_state.y() + dz * ty - vertex.position.y;

  // compute the covariance matrix. first only the trivial parts:
  float cov00 = vertex.cov00 + velo_kalman_state.c00();
  float cov10 = vertex.cov10; // state c10 is 0.f;
  float cov11 = vertex.cov11 + velo_kalman_state.c11();

  // add the contribution from the extrapolation
  cov00 += dz * dz * velo_kalman_state.c22() + 2 * std::abs(dz * velo_kalman_state.c20());
  // cov10 is unchanged: state c32, c30 and c21 are  0.f
  cov11 += dz * dz * velo_kalman_state.c33() + 2 * dz * velo_kalman_state.c31();

  // add the contribution from pv Z
  cov00 += tx * tx * vertex.cov22 - 2 * tx * vertex.cov20;
  cov10 += tx * ty * vertex.cov22 - ty * vertex.cov20 - tx * vertex.cov21;
  cov11 += ty * ty * vertex.cov22 - 2 * ty * vertex.cov21;

  // invert the covariance matrix
  float D = cov00 * cov11 - cov10 * cov10;
  float invcov00 = cov11 / D;
  float invcov10 = -cov10 / D;
  float invcov11 = cov00 / D;

  return dx * dx * invcov00 + 2 * dx * dy * invcov10 + dy * dy * invcov11;
}

float veloDOCAz(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  float dx = velo_kalman_state.x() - vertex.position.x;
  float dy = velo_kalman_state.y() - vertex.position.y;
  float tx = velo_kalman_state.tx();
  float ty = velo_kalman_state.ty();
  return std::abs(ty * dx - tx * dy) / std::sqrt(tx * tx + ty * ty);
}

std::vector<Checker::Tracks> prepareKalmanTracks(
  const unsigned number_of_events,
  gsl::span<const Allen::Views::Physics::MultiEventLongTracks> multi_event_long_tracks_view,
  gsl::span<const Allen::Views::Velo::Consolidated::States> velo_states,
  const char* scifi_geometry,
  gsl::span<const ParKalmanFilter::FittedTrack> kf_tracks,
  gsl::span<const PV::Vertex> rec_vertex,
  gsl::span<const unsigned> number_of_vertex,
  gsl::span<const mask_t> event_list)
{
  const SciFi::SciFiGeometry scifi_geom(scifi_geometry);
  std::vector<Checker::Tracks> checker_tracks(number_of_events);

  // Loop over events.
  for (unsigned i_evlist = 0; i_evlist < event_list.size(); i_evlist++) {
    const auto i_event = event_list[i_evlist];
    auto& tracks = checker_tracks[i_event];

    // Make the long tracks.
    const auto event_long_tracks = multi_event_long_tracks_view.data()->container(i_event);
    const auto number_of_tracks_event = event_long_tracks.size();
    const unsigned event_offset = event_long_tracks.offset();

    // Make the VELO states.
    const auto endvelo_states = velo_states[i_event];

    tracks.resize(number_of_tracks_event);

    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      auto& t = tracks[i_track];

      const auto long_track = event_long_tracks.track(i_track);

      const auto velo_track = long_track.track_segment<Allen::Views::Physics::Track::segment::velo>();
      const auto velo_track_index = velo_track.track_index();
      const auto velo_state = endvelo_states.state(velo_track_index);

      // add all hits
      const auto total_number_of_hits = long_track.number_of_hits();
      for (unsigned int ihit = 0; ihit < total_number_of_hits; ihit++) {
        const auto id = long_track.get_id(ihit);
        t.addId(id);
      }

      ParKalmanFilter::FittedTrack track = kf_tracks[event_offset + i_track];

      // Calculate IP.
      t.kalman_ip_chi2 = 9999.;
      t.velo_ip_chi2 = 9999.;
      for (unsigned i_vertex = 0; i_vertex < number_of_vertex[i_event]; ++i_vertex) {
        const auto vertex = rec_vertex[i_event * PatPV::max_number_vertices + i_vertex];

        float locIPChi2 = ipChi2Kalman(track, vertex);
        if (locIPChi2 < t.kalman_ip_chi2) {
          t.kalman_ip = ipKalman(track, vertex);
          t.kalman_ip_chi2 = locIPChi2;
          t.kalman_ipx = ipxKalman(track, vertex);
          t.kalman_ipy = ipyKalman(track, vertex);
          t.kalman_docaz = kalmanDOCAz(track, vertex);
        }
        locIPChi2 = ipChi2Velo(velo_state, vertex);
        if (locIPChi2 < t.velo_ip_chi2) {
          t.velo_ip = ipVelo(velo_state, vertex);
          t.velo_ip_chi2 = locIPChi2;
          t.velo_ipx = ipxVelo(velo_state, vertex);
          t.velo_ipy = ipyVelo(velo_state, vertex);
          t.velo_docaz = veloDOCAz(velo_state, vertex);
        }
      }

      // Get kalman filter information.
      // t.kalman_ip_chi2 = (float) track.ipChi2;
      t.z = (float) track.z;
      t.x = (float) track.state[0];
      t.y = (float) track.state[1];
      t.tx = (float) track.state[2];
      t.ty = (float) track.state[3];
      t.qop = (float) track.state[4];
      t.chi2 = (float) track.chi2;
      t.chi2V = (float) track.chi2V;
      t.chi2T = (float) track.chi2T;
      t.ndof = track.ndof;
      t.ndofV = track.ndofV;
      t.ndofT = track.ndofT;
      t.first_qop = (float) track.first_qop;
      t.best_qop = (float) track.best_qop;
      t.p = (float) track.p();
      t.pt = (float) track.pt();
    } // Track loop.
  }   // Event loop.

  return checker_tracks;
}
