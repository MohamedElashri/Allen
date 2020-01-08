#include "IsMuon.cuh"
#include "SystemOfUnits.h"

void is_muon_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_muon_track_occupancies>(
    Muon::Constants::n_stations * host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_is_muon>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
}

void is_muon_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function(dim3(host_buffers.host_number_of_selected_events[0]), dim3(32, Muon::Constants::n_stations), cuda_stream)(
    offset<dev_atomics_scifi_t>(arguments),
    offset<dev_scifi_track_hit_number_t>(arguments),
    offset<dev_scifi_qop_t>(arguments),
    offset<dev_scifi_states_t>(arguments),
    offset<dev_scifi_track_ut_indices_t>(arguments),
    offset<dev_muon_hits_t>(arguments),
    offset<dev_muon_track_occupancies_t>(arguments),
    offset<dev_is_muon_t>(arguments),
    constants.dev_muon_foi,
    constants.dev_muon_momentum_cuts);
  
  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_is_muon,
      offset<dev_is_muon_t>(arguments),
      size<dev_is_muon_t>(arguments),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}

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

__global__ void is_muon(
  uint* dev_atomics_scifi,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_scifi_track_ut_indices,
  const Muon::HitsSoA* muon_hits,
  int* dev_muon_track_occupancies,
  bool* dev_is_muon,
  const Muon::Constants::FieldOfInterest* dev_muon_foi,
  const float* dev_muon_momentum_cuts)
{
  const uint number_of_events = gridDim.x;
  const uint event_id = blockIdx.x;

  SciFi::Consolidated::Tracks scifi_tracks {(uint*) dev_atomics_scifi,
                                            dev_scifi_track_hit_number,
                                            dev_scifi_qop,
                                            dev_scifi_states,
                                            dev_scifi_track_ut_indices,
                                            event_id,
                                            number_of_events};

  const Muon::HitsSoA& muon_hits_event = muon_hits[event_id];

  const uint number_of_tracks_event = scifi_tracks.number_of_tracks(event_id);
  const uint event_offset = scifi_tracks.tracks_offset(event_id);

  for (uint track_id = threadIdx.x; track_id < number_of_tracks_event; track_id += blockDim.x) {
    const float momentum = 1 / fabsf(scifi_tracks.qop[track_id]);
    const uint track_offset = (event_offset + track_id) * Muon::Constants::n_stations;

    __syncthreads();

    for (uint station_id = threadIdx.y; station_id < Muon::Constants::n_stations; station_id += blockDim.y) {
      const int station_offset = muon_hits_event.station_offsets[station_id] - muon_hits_event.station_offsets[0];
      const int number_of_hits = muon_hits_event.number_of_hits_per_station[station_id];
      const float station_z = muon_hits_event.z[station_offset];

      const float extrapolation_x = scifi_tracks.states[track_id].x +
                                    scifi_tracks.states[track_id].tx * (station_z - scifi_tracks.states[track_id].z);
      const float extrapolation_y = scifi_tracks.states[track_id].y +
                                    scifi_tracks.states[track_id].ty * (station_z - scifi_tracks.states[track_id].z);

      dev_muon_track_occupancies[track_offset + station_id] = 0;
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
          dev_muon_track_occupancies[track_offset + station_id] += 1;
        }
      }
    }

    __syncthreads();

    if (threadIdx.y == 0) {
      if (momentum < dev_muon_momentum_cuts[0]) {
        dev_is_muon[event_offset + track_id] = false;
      }
      else if (dev_muon_track_occupancies[track_offset + 0] == 0 || dev_muon_track_occupancies[track_offset + 1] == 0) {
        dev_is_muon[event_offset + track_id] = false;
      }
      else if (momentum < dev_muon_momentum_cuts[1]) {
        dev_is_muon[event_offset + track_id] = true;
      }
      else if (momentum < dev_muon_momentum_cuts[2]) {
        dev_is_muon[event_offset + track_id] =
          (dev_muon_track_occupancies[track_offset + 2] != 0) || (dev_muon_track_occupancies[track_offset + 3] != 0);
      }
      else {
        dev_is_muon[event_offset + track_id] =
          (dev_muon_track_occupancies[track_offset + 2] != 0) && (dev_muon_track_occupancies[track_offset + 3] != 0);
      }
    }
  }
}
