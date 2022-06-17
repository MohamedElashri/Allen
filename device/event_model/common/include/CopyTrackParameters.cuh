/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once
#include "ParKalmanFittedTrack.cuh"
#include "ParKalmanMath.cuh"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"

__device__ inline void prepare_long_tracks(
  const Allen::Views::Physics::LongTracks event_long_tracks,
  const Allen::Views::Physics::KalmanStates endvelo_states,
  Checker::Track* long_checker_tracks)
{
  const unsigned number_of_tracks_event = event_long_tracks.size();
  for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
    Checker::Track t;
    const auto long_track = event_long_tracks.track(i_track);

    const auto velo_track = long_track.track_segment<Allen::Views::Physics::Track::segment::velo>();
    const auto velo_track_index = velo_track.track_index();
    const auto velo_state = endvelo_states.state(velo_track_index);
    t.velo_track_index = velo_track_index;
    // momentum
    const auto qop = long_track.qop();
    t.p = 1.f / std::abs(qop);
    t.qop = qop;
    // direction at first state -> velo state of track
    const auto tx = velo_state.tx();
    const auto ty = velo_state.ty();
    const auto slope2 = tx * tx + ty * ty;
    t.pt = std::sqrt(slope2 / (1.0 + slope2)) / std::fabs(qop);
    // pseudorapidity
    const auto rho = std::sqrt(slope2);
    t.rho = rho;

    // add all hits
    const auto total_number_of_hits = long_track.number_of_hits();
    for (unsigned int ihit = 0; ihit < total_number_of_hits; ihit++) {
      const auto id = long_track.get_id(ihit);
      t.addId(id);
    }
    long_checker_tracks[i_track] = t;
  }
}

__device__ inline void
prepare_muons(const unsigned number_of_tracks_event, Checker::Track* long_checker_tracks, const bool* is_muon)
{
  for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
    long_checker_tracks[i_track].is_muon = is_muon[i_track];
  }
}

__device__ inline float ipKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float tx = track.state[2];
  float ty = track.state[3];
  float dz = vertex.position.z - track.z;
  float dx = track.state[0] + dz * tx - vertex.position.x;
  float dy = track.state[1] + dz * ty - vertex.position.y;
  return std::sqrt((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

__device__ inline float ipxKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float tx = track.state[2];
  float dz = vertex.position.z - track.z;
  float dx = track.state[0] + dz * tx - vertex.position.x;
  return dx;
}

__device__ inline float ipyKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float ty = track.state[3];
  float dz = vertex.position.z - track.z;
  float dy = track.state[1] + dz * ty - vertex.position.y;
  return dy;
}

__device__ inline float ipChi2Kalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
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

__device__ inline float kalmanDOCAz(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  float dx = track.state[0] - vertex.position.x;
  float dy = track.state[1] - vertex.position.y;
  float tx = track.state[2];
  float ty = track.state[3];
  return std::abs(ty * dx - tx * dy) / std::sqrt(tx * tx + ty * ty);
}

__device__ inline float ipVelo(const Allen::Views::Physics::KalmanState& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_state.tx();
  float ty = velo_kalman_state.ty();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dx = velo_kalman_state.x() + dz * tx - vertex.position.x;
  float dy = velo_kalman_state.y() + dz * ty - vertex.position.y;
  return std::sqrt((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

__device__ inline float ipxVelo(const Allen::Views::Physics::KalmanState& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_state.tx();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dx = velo_kalman_state.x() + dz * tx - vertex.position.x;
  return dx;
}

__device__ inline float ipyVelo(const Allen::Views::Physics::KalmanState& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float ty = velo_kalman_state.ty();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dy = velo_kalman_state.y() + dz * ty - vertex.position.y;
  return dy;
}

__device__ inline float ipChi2Velo(
  const Allen::Views::Physics::KalmanState& velo_kalman_state,
  const PV::Vertex& vertex)
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

__device__ inline float veloDOCAz(const Allen::Views::Physics::KalmanState& velo_kalman_state, const PV::Vertex& vertex)
{
  float dx = velo_kalman_state.x() - vertex.position.x;
  float dy = velo_kalman_state.y() - vertex.position.y;
  float tx = velo_kalman_state.tx();
  float ty = velo_kalman_state.ty();
  return std::abs(ty * dx - tx * dy) / std::sqrt(tx * tx + ty * ty);
}

__device__ __host__ inline float eta_from_rho(const float rho)
{
  const float z = 1.f;
  if (rho > 0.f) {

    // value to control Taylor expansion of sqrt
    // constant value from std::pow(std::numeric_limits<float>::epsilon(), static_cast<float>(-.25));
    constexpr float big_z_scaled = 53.817371f;
    float z_scaled = z / rho;
    if (std::fabs(z_scaled) < big_z_scaled) {
      return std::log(z_scaled + std::sqrt(z_scaled * z_scaled + 1.f));
    }
    else {
      // apply correction using first order Taylor expansion of sqrt
      return z > 0.f ? std::log(2.f * z_scaled + 0.5f / z_scaled) : -std::log(-2.f * z_scaled);
    }
  }
  // case vector has rho = 0
  return z + 22756.f;
}

__device__ inline void prepare_kalman_tracks(
  const unsigned number_of_tracks,
  const unsigned number_of_vertices,
  const PV::Vertex* rec_vertices,
  const Allen::Views::Physics::KalmanStates endvelo_states,
  const ParKalmanFilter::FittedTrack* kf_tracks,
  Checker::Track* kalman_checker_tracks)
{
  for (unsigned i_track = 0; i_track < number_of_tracks; i_track++) {
    ParKalmanFilter::FittedTrack track = kf_tracks[i_track];
    auto t = kalman_checker_tracks[i_track];
    const auto velo_state = endvelo_states.state(t.velo_track_index);
    // Calculate IP.
    t.kalman_ip_chi2 = 9999.;
    t.velo_ip_chi2 = 9999.;
    for (unsigned i_vertex = 0; i_vertex < number_of_vertices; ++i_vertex) {
      const auto vertex = rec_vertices[i_vertex];

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
    kalman_checker_tracks[i_track] = t;
  }
}