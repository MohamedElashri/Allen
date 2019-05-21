#include <Common.h>
#include <KalmanPVIPChi2.cuh>
#include <Handler.cuh>
#include <PV_Definitions.cuh>
#include <SciFiConsolidated.cuh>
#include <AssociateConsolidated.cuh>
#include <AssociateConstants.cuh>
#include <gsl-lite.hpp>

namespace Distance {
  __device__ float
  kalman_ipchi2(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
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
    cov00 += dz * dz * track.cov(2, 2) + 2 * dz * track.cov(2, 0);
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
}

typedef float (*distance_fun)(
  const ParKalmanFilter::FittedTrack& track,
  const PV::Vertex& vertex);

__device__ void associate(
  ParKalmanFilter::FittedTrack* tracks,
  gsl::span<const PV::Vertex> const& vertices,
  Associate::Consolidated::EventTable& table,
  distance_fun fun)
{
  for (int i = threadIdx.x; i < table.size; i += blockDim.x) {
    float best_value = 0.f;
    short best_index = 0;
    bool first = true;
    for (uint j = 0; j < vertices.size(); ++j) {
      float val = std::fabs(fun(tracks[i], *(vertices.data() + j)));
      best_index = (first || val < best_value) ? j : best_index;
      best_value = (first || val < best_value) ? val : best_value;
      first = false;
    }
    if (best_value > 16) best_index = 999;
    table.pv[i] = best_index;
    table.value[i] = best_value;
    tracks[i].ipChi2 = best_value;
  }
}

__global__ void kalman_pv_ipchi2(
  ParKalmanFilter::FittedTrack* dev_kf_tracks,
  int* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number,
  char* dev_scifi_consolidated_hits,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_ut_indices,
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  char* dev_kalman_pv_ipchi2)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Consolidated SciFi tracks.
  const SciFi::Consolidated::Tracks scifi_tracks {
    (uint*) dev_n_scifi_tracks,
      (uint*) dev_scifi_track_hit_number,
      (float*) dev_scifi_qop,
      (MiniState*) dev_scifi_states,
      (uint*) dev_ut_indices,
      event_number,
      number_of_events};
  const uint event_tracks_offset = scifi_tracks.tracks_offset(event_number);

  // The total track-PV association table.
  Associate::Consolidated::Table kalman_pv_ipchi2 {dev_kalman_pv_ipchi2, scifi_tracks.total_number_of_tracks};
  // I don't think we need to actually use this cutoff.
  //kalman_pv_ipchi2.set_cutoff(Associate::KalmanPVIPChi2::baseline);

  // Kalman-fitted tracks for this event.
  ParKalmanFilter::FittedTrack* event_tracks = dev_kf_tracks + event_tracks_offset;
  gsl::span<PV::Vertex const> vertices {dev_multi_fit_vertices + event_number * PV::max_number_vertices,
      *(dev_number_of_multi_fit_vertices + event_number)};

  // The track <-> PV association table for this event.
  auto pv_table = kalman_pv_ipchi2.event_table(scifi_tracks, event_number);

  // Perform the association for this event.
  associate(event_tracks, vertices, pv_table, Distance::kalman_ipchi2);
  
}
