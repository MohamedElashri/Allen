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
  __device__ float kalman_ipchi2(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex)
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
} // namespace Distance

__device__ void associate_and_muon_id(
  ParKalmanFilter::FittedTrack* tracks,
  const bool* is_muon,
  Allen::device::span<const PV::Vertex> const& vertices,
  Associate::Consolidated::EventTable& table)
{
  for (unsigned i = threadIdx.x; i < table.size(); i += blockDim.x) {
    float best_value = 0.f;
    short best_index = 0;
    bool first = true;
    for (unsigned j = 0; j < vertices.size(); ++j) {
      float val = fabsf(Distance::kalman_ipchi2(tracks[i], *(vertices.data() + j)));
      best_index = (first || val < best_value) ? j : best_index;
      best_value = (first || val < best_value) ? val : best_value;
      first = false;
    }
    table.pv(i) = best_index;
    table.value(i) = best_value;
    tracks[i].ipChi2 = best_value;
    tracks[i].is_muon = is_muon[i];
  }
}

__global__ void kalman_velo_only::kalman_pv_ipchi2(kalman_velo_only::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Consolidated SciFi tracks
  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_number,
                                                 number_of_events};

  const unsigned event_tracks_offset = scifi_tracks.tracks_offset(event_number);

  // The total track-PV association table.
  Associate::Consolidated::Table kalman_pv_ipchi2 {parameters.dev_kalman_pv_ipchi2,
                                                   scifi_tracks.total_number_of_tracks()};

  // Kalman-fitted tracks for this event.
  ParKalmanFilter::FittedTrack* event_tracks = parameters.dev_kf_tracks + event_tracks_offset;
  const bool* event_is_muon = parameters.dev_is_muon + event_tracks_offset;
  Allen::device::span<PV::Vertex const> vertices {parameters.dev_multi_fit_vertices +
                                                    event_number * PV::max_number_vertices,
                                                  *(parameters.dev_number_of_multi_fit_vertices + event_number)};

  // The track <-> PV association table for this event.
  Associate::Consolidated::EventTable pv_table = kalman_pv_ipchi2.event_table(scifi_tracks, event_number);

  // Perform the association for this event.
  associate_and_muon_id(event_tracks, event_is_muon, vertices, pv_table);
}
