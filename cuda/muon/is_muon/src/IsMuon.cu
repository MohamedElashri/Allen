#include "IsMuon.cuh"
#include "SystemOfUnits.h"

__device__ float elliptical_foi_window(const float a, const float b, const float c, const float momentum)
{
  return a + b * expf(-c * momentum / Gaudi::Units::GeV);
}

__device__ std::pair<float, float> field_of_interest(
  const Muon::Constants::FieldOfInterest* dev_muon_foi,
  const int station,
  const int region,
  const float momentum)
{
  if (momentum < 1000 * Gaudi::Units::GeV) {
    return {elliptical_foi_window(
              dev_muon_foi->param_a_x[station][region],
              dev_muon_foi->param_b_x[station][region],
              dev_muon_foi->param_c_x[station][region],
              momentum),
            elliptical_foi_window(
              dev_muon_foi->param_a_y[station][region],
              dev_muon_foi->param_b_y[station][region],
              dev_muon_foi->param_c_y[station][region],
              momentum)};
  }
  else {
    return {dev_muon_foi->param_a_x[station][region], dev_muon_foi->param_a_y[station][region]};
  }
}

__device__ bool is_in_window(
  const float hit_x,
  const float hit_y,
  const float hit_dx,
  const float hit_dy,
  const Muon::Constants::FieldOfInterest* dev_muon_foi,
  const int station,
  const int region,
  const float momentum,
  const float extrapolation_x,
  const float extrapolation_y)
{
  std::pair<float, float> foi = field_of_interest(dev_muon_foi, station, region, momentum);

  return (fabsf(hit_x - extrapolation_x) < hit_dx * foi.first * dev_muon_foi->factor) &&
         (fabsf(hit_y - extrapolation_y) < hit_dy * foi.second * dev_muon_foi->factor);
}

__global__ void is_muon::is_muon(
  is_muon::Parameters parameters,
  const Muon::Constants::FieldOfInterest* dev_muon_foi,
  const float* dev_muon_momentum_cuts)
{
  const uint number_of_events = gridDim.x;
  const uint event_id = blockIdx.x;

  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_id,
                                                 number_of_events};

  const Muon::HitsSoA& muon_hits_event = parameters.dev_muon_hits[event_id];

  const uint number_of_tracks_event = scifi_tracks.number_of_tracks(event_id);
  const uint event_offset = scifi_tracks.tracks_offset(event_id);

  for (uint track_id = threadIdx.x; track_id < number_of_tracks_event; track_id += blockDim.x) {
    const float momentum = 1 / fabsf(scifi_tracks.qop(track_id));
    const uint track_offset = (event_offset + track_id) * Muon::Constants::n_stations;

    __syncthreads();

    for (uint station_id = threadIdx.y; station_id < Muon::Constants::n_stations; station_id += blockDim.y) {
      const int station_offset = muon_hits_event.station_offsets[station_id] - muon_hits_event.station_offsets[0];
      const int number_of_hits = muon_hits_event.number_of_hits_per_station[station_id];
      const float station_z = muon_hits_event.z[station_offset];
      const auto& state = scifi_tracks.states(track_id);

      const float extrapolation_x = state.x + state.tx * (station_z - state.z);
      const float extrapolation_y = state.y + state.ty * (station_z - state.z);

      parameters.dev_muon_track_occupancies[track_offset + station_id] = 0;


      for (int i_hit = 0; i_hit < number_of_hits; ++i_hit) {
        const int idx = station_offset + i_hit;
        if (is_in_window(
              muon_hits_event.x[idx],
              muon_hits_event.y[idx],
              muon_hits_event.dx[idx],
              muon_hits_event.dy[idx],
              dev_muon_foi,
              station_id,
              muon_hits_event.region_id[idx],
              momentum,
              extrapolation_x,
              extrapolation_y)) {
          parameters.dev_muon_track_occupancies[track_offset + station_id] += 1;
        }
      }
    }

    __syncthreads();

    if (threadIdx.y == 0) {
      if (momentum < dev_muon_momentum_cuts[0]) {
        parameters.dev_is_muon[event_offset + track_id] = false;
      }
      else if (
        parameters.dev_muon_track_occupancies[track_offset + 0] == 0 ||
        parameters.dev_muon_track_occupancies[track_offset + 1] == 0) {
        parameters.dev_is_muon[event_offset + track_id] = false;
      }
      else if (momentum < dev_muon_momentum_cuts[1]) {
        parameters.dev_is_muon[event_offset + track_id] = true;
      }
      else if (momentum < dev_muon_momentum_cuts[2]) {
        parameters.dev_is_muon[event_offset + track_id] =
          (parameters.dev_muon_track_occupancies[track_offset + 2] != 0) ||
          (parameters.dev_muon_track_occupancies[track_offset + 3] != 0);
      }
      else {
        parameters.dev_is_muon[event_offset + track_id] =
          (parameters.dev_muon_track_occupancies[track_offset + 2] != 0) &&
          (parameters.dev_muon_track_occupancies[track_offset + 3] != 0);
      }
    }

    // TODO: Fix and use the following code, with less branches
    // if (threadIdx.y == 0) {
    //   parameters.dev_is_muon[event_offset + track_id] =
    //     momentum >= dev_muon_momentum_cuts[0] &&                         // Condition 1
    //     (parameters.dev_muon_track_occupancies[track_offset + 0] == 0 || // Condition 2
    //      parameters.dev_muon_track_occupancies[track_offset + 1] == 0) &&
    //     (momentum < dev_muon_momentum_cuts[1] ||  // Condition 3
    //      (momentum < dev_muon_momentum_cuts[2] && // Condition 4
    //       (parameters.dev_muon_track_occupancies[track_offset + 2] != 0 ||
    //        parameters.dev_muon_track_occupancies[track_offset + 3] != 0)) ||
    //      (parameters.dev_muon_track_occupancies[track_offset + 2] != 0 && // Condition 5
    //       parameters.dev_muon_track_occupancies[track_offset + 3] != 0));
    // }
  }
}
