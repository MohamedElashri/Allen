/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "pv_beamline_extrapolate.cuh"

void pv_beamline_extrapolate::pv_beamline_extrapolate_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_pvtracks_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_pvtrack_z_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_pvtrack_unsorted_z_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void pv_beamline_extrapolate::pv_beamline_extrapolate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
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

  // const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  // const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);

  for (unsigned index = threadIdx.x; index < velo_tracks_view.size(); index += blockDim.x) {
    parameters.dev_pvtrack_unsorted_z[velo_tracks_view.offset() + index] = velo_states_view.state(index).z();
  }

  __syncthreads();

  // Insert in order
  for (unsigned index = threadIdx.x; index < velo_tracks_view.size(); index += blockDim.x) {
    const auto z = parameters.dev_pvtrack_unsorted_z[velo_tracks_view.offset() + index];
    unsigned insert_position = 0;

    for (unsigned other = 0; other < velo_tracks_view.size(); ++other) {
      const auto other_z = parameters.dev_pvtrack_unsorted_z[velo_tracks_view.offset() + other];
      insert_position += z > other_z || (z == other_z && index > other);
    }

    parameters.dev_pvtracks[velo_tracks_view.offset() + insert_position] = PVTrack {velo_states_view.state(index)};
    parameters.dev_pvtrack_z[velo_tracks_view.offset() + index] = z;
  }
}
