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

float ipVelo(
  Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_states.tx(state_index);
  float ty = velo_kalman_states.ty(state_index);
  float dz = vertex.position.z - velo_kalman_states.z(state_index);
  float dx = velo_kalman_states.x(state_index) + dz * tx - vertex.position.x;
  float dy = velo_kalman_states.y(state_index) + dz * ty - vertex.position.y;
  return std::sqrt((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

float ipxVelo(
  Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_states.tx(state_index);
  float dz = vertex.position.z - velo_kalman_states.z(state_index);
  float dx = velo_kalman_states.x(state_index) + dz * tx - vertex.position.x;
  return dx;
}

float ipyVelo(
  Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float ty = velo_kalman_states.ty(state_index);
  float dz = vertex.position.z - velo_kalman_states.z(state_index);
  float dy = velo_kalman_states.y(state_index) + dz * ty - vertex.position.y;
  return dy;
}

float ipChi2Velo(
  Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_states.tx(state_index);
  float ty = velo_kalman_states.ty(state_index);
  float dz = vertex.position.z - velo_kalman_states.z(state_index);
  float dx = velo_kalman_states.x(state_index) + dz * tx - vertex.position.x;
  float dy = velo_kalman_states.y(state_index) + dz * ty - vertex.position.y;

  // compute the covariance matrix. first only the trivial parts:
  float cov00 = vertex.cov00 + velo_kalman_states.c00(state_index);
  float cov10 = vertex.cov10; // state c10 is 0.f;
  float cov11 = vertex.cov11 + velo_kalman_states.c11(state_index);

  // add the contribution from the extrapolation
  cov00 += dz * dz * velo_kalman_states.c22(state_index) + 2 * std::abs(dz * velo_kalman_states.c20(state_index));
  // cov10 is unchanged: state c32, c30 and c21 are  0.f
  cov11 += dz * dz * velo_kalman_states.c33(state_index) + 2 * dz * velo_kalman_states.c31(state_index);

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

float veloDOCAz(
  Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex)
{
  float dx = velo_kalman_states.x(state_index) - vertex.position.x;
  float dy = velo_kalman_states.y(state_index) - vertex.position.y;
  float tx = velo_kalman_states.tx(state_index);
  float ty = velo_kalman_states.ty(state_index);
  return std::abs(ty * dx - tx * dy) / std::sqrt(tx * tx + ty * ty);
}

std::vector<Checker::Tracks> prepareKalmanTracks(
  const unsigned* velo_track_atomics,
  const unsigned* velo_track_hit_number,
  const char* velo_track_hits,
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
  const ParKalmanFilter::FittedTrack* kf_tracks,
  char* velo_states_base,
  PV::Vertex* rec_vertex,
  const int* number_of_vertex,
  const unsigned number_of_events)
{

  const SciFi::SciFiGeometry scifi_geom(scifi_geometry);
  std::vector<Checker::Tracks> checker_tracks;

  // Loop over events.
  for (unsigned i_event = 0; i_event < number_of_events; i_event++) {
    Checker::Tracks tracks; // All tracks from one event.

    // Get the vertices.
    std::vector<PV::Vertex*> vecOfVertices;
    for (int i = 0; i < number_of_vertex[i_event]; ++i) {
      int index = i_event * PatPV::max_number_vertices + i;
      vecOfVertices.push_back(&(rec_vertex[index]));
    }

    // Make the consolidated tracks.
    Velo::Consolidated::ConstTracks velo_tracks {velo_track_atomics, velo_track_hit_number, i_event, number_of_events};
    UT::Consolidated::ConstExtendedTracks ut_tracks {
      ut_track_atomics, ut_track_hit_number, ut_qop, ut_track_velo_indices, i_event, number_of_events};
    SciFi::Consolidated::ConstTracks scifi_tracks {scifi_track_atomics,
                                                   scifi_track_hit_number,
                                                   scifi_qop,
                                                   scifi_states,
                                                   scifi_track_ut_indices,
                                                   i_event,
                                                   number_of_events};

    // Make the VELO states.
    const unsigned event_velo_tracks_offset = velo_tracks.tracks_offset(i_event);
    Velo::Consolidated::ConstKalmanStates velo_states {velo_states_base, velo_tracks.total_number_of_tracks()};

    // Loop over tracks.
    const unsigned number_of_tracks_event = scifi_tracks.number_of_tracks(i_event);
    for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
      Checker::Track t;

      // Add SciFi hits.
      const unsigned scifi_track_number_of_hits = scifi_tracks.number_of_hits(i_track);
      SciFi::Consolidated::ConstHits track_hits_scifi = scifi_tracks.get_hits(scifi_track_hits, i_track);
      for (unsigned i_hit = 0; i_hit < scifi_track_number_of_hits; ++i_hit) {
        t.addId(track_hits_scifi.id(i_hit));
      }

      // Add UT hits.
      const unsigned UT_track_index = scifi_tracks.ut_track(i_track);
      const unsigned ut_track_number_of_hits = ut_tracks.number_of_hits(UT_track_index);
      UT::Consolidated::ConstHits track_hits_ut = ut_tracks.get_hits(ut_track_hits, UT_track_index);
      for (unsigned i_hit = 0; i_hit < ut_track_number_of_hits; ++i_hit) {
        t.addId(track_hits_ut.id(i_hit));
      }

      // Add Velo hits.
      const int velo_track_index = ut_tracks.velo_track(UT_track_index);
      const unsigned velo_track_number_of_hits = velo_tracks.number_of_hits(velo_track_index);
      Velo::Consolidated::ConstHits track_hits_velo = velo_tracks.get_hits(velo_track_hits, velo_track_index);
      for (unsigned i_hit = 0; i_hit < velo_track_number_of_hits; ++i_hit) {
        t.addId(track_hits_velo.id(i_hit));
      }

      ParKalmanFilter::FittedTrack track = kf_tracks[scifi_tracks.tracks_offset(i_event) + i_track];

      // Calculate IP.
      t.kalman_ip_chi2 = 9999.;
      t.velo_ip_chi2 = 9999.;
      for (auto vertex : vecOfVertices) {
        float locIPChi2 = ipChi2Kalman(track, *vertex);
        if (locIPChi2 < t.kalman_ip_chi2) {
          t.kalman_ip = ipKalman(track, *vertex);
          t.kalman_ip_chi2 = locIPChi2;
          t.kalman_ipx = ipxKalman(track, *vertex);
          t.kalman_ipy = ipyKalman(track, *vertex);
          t.kalman_docaz = kalmanDOCAz(track, *vertex);
        }
        locIPChi2 = ipChi2Velo(velo_states, event_velo_tracks_offset + velo_track_index, *vertex);
        if (locIPChi2 < t.velo_ip_chi2) {
          t.velo_ip = ipVelo(velo_states, event_velo_tracks_offset + velo_track_index, *vertex);
          t.velo_ip_chi2 = locIPChi2;
          t.velo_ipx = ipxVelo(velo_states, event_velo_tracks_offset + velo_track_index, *vertex);
          t.velo_ipy = ipyVelo(velo_states, event_velo_tracks_offset + velo_track_index, *vertex);
          t.velo_docaz = veloDOCAz(velo_states, event_velo_tracks_offset + velo_track_index, *vertex);
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

      tracks.push_back(t);

    } // Track loop.

    checker_tracks.emplace_back(tracks);

  } // Event loop.

  return checker_tracks;
}
