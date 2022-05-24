
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CopyKalmanTrackParameters.cuh"

INSTANTIATE_ALGORITHM(copy_kalman_track_parameters::copy_kalman_track_parameters_t)

__device__ float ipKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float tx = track.state[2];
  float ty = track.state[3];
  float dz = vertex.position.z - track.z;
  float dx = track.state[0] + dz * tx - vertex.position.x;
  float dy = track.state[1] + dz * ty - vertex.position.y;
  return std::sqrt((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

__device__ float ipxKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float tx = track.state[2];
  float dz = vertex.position.z - track.z;
  float dx = track.state[0] + dz * tx - vertex.position.x;
  return dx;
}

__device__ float ipyKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  // Get position information.
  float ty = track.state[3];
  float dz = vertex.position.z - track.z;
  float dy = track.state[1] + dz * ty - vertex.position.y;
  return dy;
}

__device__ float ipChi2Kalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
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

__device__ float kalmanDOCAz(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
{
  float dx = track.state[0] - vertex.position.x;
  float dy = track.state[1] - vertex.position.y;
  float tx = track.state[2];
  float ty = track.state[3];
  return std::abs(ty * dx - tx * dy) / std::sqrt(tx * tx + ty * ty);
}

__device__ float ipVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_state.tx();
  float ty = velo_kalman_state.ty();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dx = velo_kalman_state.x() + dz * tx - vertex.position.x;
  float dy = velo_kalman_state.y() + dz * ty - vertex.position.y;
  return std::sqrt((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

__device__ float ipxVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float tx = velo_kalman_state.tx();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dx = velo_kalman_state.x() + dz * tx - vertex.position.x;
  return dx;
}

__device__ float ipyVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
  float ty = velo_kalman_state.ty();
  float dz = vertex.position.z - velo_kalman_state.z();
  float dy = velo_kalman_state.y() + dz * ty - vertex.position.y;
  return dy;
}

__device__ float ipChi2Velo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
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

__device__ float veloDOCAz(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex)
{
  float dx = velo_kalman_state.x() - vertex.position.x;
  float dy = velo_kalman_state.y() - vertex.position.y;
  float tx = velo_kalman_state.tx();
  float ty = velo_kalman_state.ty();
  return std::abs(ty * dx - tx * dy) / std::sqrt(tx * tx + ty * ty);
}

__global__ void create_kalman_tracks_for_checker(copy_kalman_track_parameters::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const auto event_long_tracks = parameters.dev_multi_event_long_tracks_view->container(event_number);
  const auto number_of_tracks_event = event_long_tracks.size();
  const auto offset_kalman_tracks = event_long_tracks.offset();
  const auto endvelo_states = parameters.dev_velo_states_view[event_number];
  SciFi::KalmanCheckerTrack* kalman_checker_tracks_event = parameters.dev_kalman_checker_tracks + offset_kalman_tracks;
  const ParKalmanFilter::FittedTrack* kf_tracks_event = parameters.dev_kf_tracks + offset_kalman_tracks;
  const PV::Vertex* rec_vertices_event =
    parameters.dev_multi_final_vertices + event_number * PatPV::max_number_vertices;

  const auto number_of_vertices_event = parameters.dev_number_of_multi_final_vertices[event_number];
  for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track++) {
    SciFi::KalmanCheckerTrack t;
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
    const double tx = velo_state.tx();
    const double ty = velo_state.ty();
    const double slope2 = tx * tx + ty * ty;
    t.pt = std::sqrt(slope2 / (1.0 + slope2)) / std::abs(qop);
    // pseudorapidity
    const double rho = std::sqrt(slope2);
    t.rho = rho;

    // add all hits
    const auto total_number_of_hits = long_track.number_of_hits();
    t.total_number_of_hits = total_number_of_hits;
    for (unsigned int ihit = 0; ihit < total_number_of_hits; ihit++) {
      const auto id = long_track.get_id(ihit);
      t.allids[ihit] = id;
    }
    ParKalmanFilter::FittedTrack track = kf_tracks_event[i_track];

    // Calculate IP.
    t.kalman_ip_chi2 = 9999.;
    t.velo_ip_chi2 = 9999.;
    for (unsigned i_vertex = 0; i_vertex < number_of_vertices_event; ++i_vertex) {
      const auto vertex = rec_vertices_event[i_vertex];

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
    kalman_checker_tracks_event[i_track] = t;
  }
}

void copy_kalman_track_parameters::copy_kalman_track_parameters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_kalman_checker_tracks_t>(arguments, first<host_number_of_reconstructed_long_tracks_t>(arguments));
}

void copy_kalman_track_parameters::copy_kalman_track_parameters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(create_kalman_tracks_for_checker)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
  assign_to_host_buffer<dev_kalman_checker_tracks_t>(host_buffers.host_kalman_checker_tracks, arguments, context);
}