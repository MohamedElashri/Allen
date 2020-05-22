#include "IsMuon.cuh"
#include "SystemOfUnits.h"

void is_muon::is_muon_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_muon_track_occupancies_t>(
    arguments, Muon::Constants::n_stations * first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_is_muon_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void is_muon::is_muon_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_muon_track_occupancies_t>(arguments, 0, cuda_stream);

  global_function(is_muon)(
    dim3(first<host_number_of_selected_events_t>(arguments)), dim3(32, Muon::Constants::n_stations), cuda_stream)(
    arguments, constants.dev_muon_foi, constants.dev_muon_momentum_cuts);

  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_is_muon,
      data<dev_is_muon_t>(arguments),
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
    return {
      elliptical_foi_window(
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
  const uint event_number = blockIdx.x;

  const auto muon_total_number_of_hits =
    parameters.dev_station_ocurrences_offset[number_of_events * Muon::Constants::n_stations];
  const auto station_ocurrences_offset =
    parameters.dev_station_ocurrences_offset + event_number * Muon::Constants::n_stations;

  SciFi::Consolidated::ConstTracks scifi_tracks {
    parameters.dev_atomics_scifi,
    parameters.dev_scifi_track_hit_number,
    parameters.dev_scifi_qop,
    parameters.dev_scifi_states,
    parameters.dev_scifi_track_ut_indices,
    event_number,
    number_of_events};

  const auto muon_hits = Muon::ConstHits {parameters.dev_muon_hits, muon_total_number_of_hits};

  const uint number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
  const uint event_offset = scifi_tracks.tracks_offset(event_number);

  for (uint track_id = threadIdx.x; track_id < number_of_tracks_event; track_id += blockDim.x) {
    const float momentum = 1 / fabsf(scifi_tracks.qop(track_id));
    const uint track_offset = (event_offset + track_id) * Muon::Constants::n_stations;

    __syncthreads();

    for (uint station_id = threadIdx.y; station_id < Muon::Constants::n_stations; station_id += blockDim.y) {
      const int number_of_hits = station_ocurrences_offset[station_id + 1] - station_ocurrences_offset[station_id];
      const auto& state = scifi_tracks.states(track_id);

      for (int i_hit = 0; i_hit < number_of_hits; ++i_hit) {
        const int idx = station_ocurrences_offset[station_id] + i_hit;
        const float extrapolation_x = state.x + state.tx * (muon_hits.z(idx) - state.z);
        const float extrapolation_y = state.y + state.ty * (muon_hits.z(idx) - state.z);
        if (is_in_window(
              muon_hits.x(idx),
              muon_hits.y(idx),
              muon_hits.dx(idx),
              muon_hits.dy(idx),
              dev_muon_foi,
              station_id,
              muon_hits.region(idx),
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
