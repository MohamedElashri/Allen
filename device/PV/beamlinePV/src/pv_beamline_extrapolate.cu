/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "pv_beamline_extrapolate.cuh"

INSTANTIATE_ALGORITHM(pv_beamline_extrapolate::pv_beamline_extrapolate_t)

void pv_beamline_extrapolate::pv_beamline_extrapolate_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_pvtracks_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void pv_beamline_extrapolate::pv_beamline_extrapolate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(pv_beamline_extrapolate)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void pv_beamline_extrapolate::pv_beamline_extrapolate(pv_beamline_extrapolate::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto velo_tracks_view = parameters.dev_velo_tracks_view[event_number];
  const auto velo_states_view = parameters.dev_velo_states_view[event_number];

  for (unsigned index = threadIdx.x; index < velo_tracks_view.size(); index += blockDim.x) {
    parameters.dev_pvtracks[velo_tracks_view.offset() + index] = PVTrack {velo_states_view.state(index)};
  }
}
