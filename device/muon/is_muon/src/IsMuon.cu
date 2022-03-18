/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "IsMuon.cuh"
#include "SystemOfUnits.h"

INSTANTIATE_ALGORITHM(is_muon::is_muon_t)

void is_muon::is_muon_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_is_muon_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void is_muon::is_muon_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(is_muon)(dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
    arguments, constants.dev_muon_foi, constants.dev_muon_momentum_cuts);

  if (runtime_options.fill_extra_host_buffers) {
    assign_to_host_buffer<dev_is_muon_t>(host_buffers.host_is_muon, arguments, context);
  }
}

__device__ float elliptical_foi_window(const float a, const float b, const float c, const float momentum)
{
  return a + b * expf(-c * momentum / Gaudi::Units::GeV);
}

__device__ std::pair<float, float> field_of_interest(
  const Muon::Constants::FieldOfInterest* muon_foi_params,
  const int station,
  const int region,
  const float momentum)
{
  return {elliptical_foi_window(
            muon_foi_params->param(Muon::Constants::FoiParams::a, Muon::Constants::FoiParams::x, station, region),
            muon_foi_params->param(Muon::Constants::FoiParams::b, Muon::Constants::FoiParams::x, station, region),
            muon_foi_params->param(Muon::Constants::FoiParams::c, Muon::Constants::FoiParams::x, station, region),
            momentum),
          elliptical_foi_window(
            muon_foi_params->param(Muon::Constants::FoiParams::a, Muon::Constants::FoiParams::y, station, region),
            muon_foi_params->param(Muon::Constants::FoiParams::b, Muon::Constants::FoiParams::y, station, region),
            muon_foi_params->param(Muon::Constants::FoiParams::c, Muon::Constants::FoiParams::y, station, region),
            momentum)};
}

__device__ bool is_in_window(
  const float hit_x,
  const float hit_y,
  const float hit_dx,
  const float hit_dy,
  const Muon::Constants::FieldOfInterest* muon_foi_params,
  const int station,
  const int region,
  const float momentum,
  const float extrapolation_x,
  const float extrapolation_y)
{
  std::pair<float, float> foi = field_of_interest(muon_foi_params, station, region, momentum);

  return (fabsf(hit_x - extrapolation_x) < hit_dx * foi.first * muon_foi_params->factor()) &&
         (fabsf(hit_y - extrapolation_y) < hit_dy * foi.second * muon_foi_params->factor());
}

__global__ void is_muon::is_muon(
  is_muon::Parameters parameters,
  const Muon::Constants::FieldOfInterest* dev_muon_foi,
  const float* dev_muon_momentum_cuts)
{
  // Put foi parameters in shared memory
  __shared__ int8_t shared_muon_foi_params_content[sizeof(Muon::Constants::FieldOfInterest)];
  Muon::Constants::FieldOfInterest* shared_muon_foi_params =
    reinterpret_cast<Muon::Constants::FieldOfInterest*>(shared_muon_foi_params_content);

  if (threadIdx.x == 0) {
    shared_muon_foi_params->set_factor(dev_muon_foi->factor());
  }

  for (unsigned i = threadIdx.x;
       i < Muon::Constants::FoiParams::n_parameters * Muon::Constants::FoiParams::n_coordinates *
             Muon::Constants::n_stations * Muon::Constants::n_regions;
       i += blockDim.x) {
    shared_muon_foi_params->params_begin()[i] = dev_muon_foi->params_begin_const()[i];
  }

  // Due to shared_muon_foi_params
  __syncthreads();

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto muon_total_number_of_hits =
    parameters.dev_station_ocurrences_offset[number_of_events * Muon::Constants::n_stations];
  const auto station_ocurrences_offset =
    parameters.dev_station_ocurrences_offset + event_number * Muon::Constants::n_stations;

  const auto scifi_tracks_view = parameters.dev_scifi_tracks_view[event_number];
  const auto scifi_states = parameters.dev_scifi_states + scifi_tracks_view.offset();

  const auto muon_hits = Muon::ConstHits {parameters.dev_muon_hits, muon_total_number_of_hits};

  const unsigned number_of_tracks_event = scifi_tracks_view.size();
  const unsigned event_offset = scifi_tracks_view.offset();

  for (unsigned track_id = threadIdx.x; track_id < number_of_tracks_event; track_id += blockDim.x) {
    const auto scifi_track = scifi_tracks_view.track(track_id);
    const float momentum = 1.f / fabsf(scifi_track.qop());

    if (momentum < dev_muon_momentum_cuts[0]) {
      parameters.dev_is_muon[event_offset + track_id] = false;
      continue;
    }
    const auto& state = scifi_tracks.states(track_id);

    unsigned occupancies[Muon::Constants::n_stations];

    for (unsigned station_id = 0; station_id < Muon::Constants::n_stations; ++station_id) {
      occupancies[station_id] = 0;
      const int number_of_hits = station_ocurrences_offset[station_id + 1] - station_ocurrences_offset[station_id];

      for (int i_hit = 0; i_hit < number_of_hits; ++i_hit) {
        const int idx = station_ocurrences_offset[station_id] + i_hit;
        const float extrapolation_x = state.x + state.tx * (muon_hits.z(idx) - state.z);
        const float extrapolation_y = state.y + state.ty * (muon_hits.z(idx) - state.z);
        occupancies[station_id] += is_in_window(
          muon_hits.x(idx),
          muon_hits.y(idx),
          muon_hits.dx(idx),
          muon_hits.dy(idx),
          dev_muon_foi,
          station_id,
          muon_hits.region(idx),
          momentum,
          extrapolation_x,
          extrapolation_y);
      }
    }

    if (occupancies[0] == 0 || occupancies[1] == 0) {
      parameters.dev_is_muon[event_offset + track_id] = false;
    }
    else if (momentum < dev_muon_momentum_cuts[1]) {
      parameters.dev_is_muon[event_offset + track_id] = true;
    }
    else if (momentum < dev_muon_momentum_cuts[2]) {
      parameters.dev_is_muon[event_offset + track_id] = (occupancies[2] != 0) || (occupancies[3] != 0);
    }
    else {
      parameters.dev_is_muon[event_offset + track_id] = (occupancies[2] != 0) && (occupancies[3] != 0);
    }
  }
}
