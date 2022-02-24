/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <Common.h>
#include <ParKalmanVeloOnly.cuh>
#include <PV_Definitions.cuh>
#include <SciFiConsolidated.cuh>
#include <AssociateConsolidated.cuh>
#include <AssociateConstants.cuh>

namespace Distance {
  __device__ float kalman_ipchi2(const Allen::Views::Physics::KalmanState& track, const PV::Vertex& vertex)
  {
    // Get position information.
    float tx = track.tx();
    float ty = track.ty();
    float dz = vertex.position.z - track.z();
    float dx = track.x() + dz * tx - vertex.position.x;
    float dy = track.y() + dz * ty - vertex.position.y;

    // Build covariance matrix.
    float cov00 = vertex.cov00 + track.c00();
    float cov10 = vertex.cov10;
    float cov11 = vertex.cov11 + track.c11();

    // Add contribution from extrapolation.
    cov00 += dz * dz * track.c22() + 2 * dz * track.c20();
    cov11 += dz * dz * track.c33() + 2 * dz * track.c31();

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
} // namespace Distance

__device__ float kalman_ip(const Allen::Views::Physics::KalmanState& track, const PV::Vertex& vertex)
{
  const float tx = track.tx();
  const float ty = track.ty();
  const float dz = vertex.position.z - track.z();
  const float dx = track.x() + dz * tx - vertex.position.x;
  const float dy = track.y() + dz * ty - vertex.position.y;
  return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
}

__device__ void associate_and_muon_id(
  ParKalmanFilter::FittedTrack* tracks,
  const Allen::Views::Physics::KalmanStates& states,
  const bool* is_muon,
  Allen::device::span<const PV::Vertex> const& vertices,
  Associate::Consolidated::EventTable& table)
{
  for (unsigned i = threadIdx.x; i < table.size(); i += blockDim.x) {
    float best_value = 0.f;
    short best_index = -1;
    float best_pvz = -999999.f;
    bool first = true;
    for (unsigned j = 0; j < vertices.size(); ++j) {
      float val = fabsf(Distance::kalman_ipchi2(states.state(i), *(vertices.data() + j)));
      best_index = (first || val < best_value) ? j : best_index;
      best_value = (first || val < best_value) ? val : best_value;
      best_pvz   = (first || val < best_value) ? pv.position.z : best_pvz;
      first = false;
    }
    table.pv(i) = best_index;
    table.value(i) = best_value;
    tracks[i].ipChi2 = best_value;
    tracks[i].is_muon = is_muon[i];
    tracks[i].bpv_z = best_pvz;
  }
}

__global__ void kalman_velo_only::kalman_pv_ipchi2(kalman_velo_only::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto event_scifi_tracks = parameters.dev_scifi_tracks_view->container(event_number);
  const auto kalman_states_view = parameters.dev_kalman_states_view[event_number];
  const unsigned total_number_of_scifi_tracks = parameters.dev_scifi_tracks_view->number_of_contained_objects();

  // The total track-PV association table.
  Associate::Consolidated::Table kalman_pv_ipchi2 {parameters.dev_kalman_pv_ipchi2, total_number_of_scifi_tracks};
  parameters.dev_kalman_pv_tables[event_number] = Allen::Views::Physics::PVTable {parameters.dev_kalman_pv_ipchi2,
                                                                                  event_scifi_tracks.offset(),
                                                                                  total_number_of_scifi_tracks,
                                                                                  event_scifi_tracks.size()};

  // Kalman-fitted tracks for this event.
  ParKalmanFilter::FittedTrack* event_tracks = parameters.dev_kf_tracks + event_scifi_tracks.offset();
  const bool* event_is_muon = parameters.dev_is_muon + event_scifi_tracks.offset();
  Allen::device::span<PV::Vertex const> vertices {parameters.dev_multi_final_vertices +
                                                    event_number * PV::max_number_vertices,
                                                  *(parameters.dev_number_of_multi_final_vertices + event_number)};

  // The track <-> PV association table for this event.
  Associate::Consolidated::EventTable pv_table =
    kalman_pv_ipchi2.event_table(event_scifi_tracks.offset(), event_scifi_tracks.size());

  // Perform the association for this event.
  associate_and_muon_id(event_tracks, kalman_states_view, event_is_muon, vertices, pv_table);
}
