/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "pv_beamline_calculate_denom.cuh"

void pv_beamline_calculate_denom::pv_beamline_calculate_denom_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_pvtracks_denom_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void pv_beamline_calculate_denom::pv_beamline_calculate_denom_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(pv_beamline_calculate_denom)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);
}

__global__ void pv_beamline_calculate_denom::pv_beamline_calculate_denom(
  pv_beamline_calculate_denom::Parameters parameters)
{
  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;

  const Velo::Consolidated::Tracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  const unsigned number_of_tracks = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const float* zseeds = parameters.dev_zpeaks + event_number * PV::max_number_vertices;
  const unsigned number_of_seeds = parameters.dev_number_of_zpeaks[event_number];

  const PVTrack* tracks = parameters.dev_pvtracks + event_tracks_offset;
  float* pvtracks_denom = parameters.dev_pvtracks_denom + event_tracks_offset;

  // Precalculate all track denoms
  for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    auto track_denom = 0.f;
    const auto track = tracks[i];

    for (unsigned j = 0; j < number_of_seeds; ++j) {
      const auto dz = zseeds[j] - track.z;
      const float2 res = track.x + track.tx * dz;
      const auto chi2 = res.x * res.x * track.W_00 + res.y * res.y * track.W_11;
      track_denom += expf(chi2 * (-0.5f));
    }

    pvtracks_denom[i] = track_denom;
  }
}
