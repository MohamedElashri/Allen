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
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(pv_beamline_extrapolate)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);
}

__global__ void pv_beamline_extrapolate::pv_beamline_extrapolate(pv_beamline_extrapolate::Parameters parameters)
{
  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;

  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {
    parameters.dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks()};

  const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);
  const unsigned total_number_of_tracks = velo_tracks.total_number_of_tracks();

  for (unsigned index = threadIdx.x; index < number_of_tracks_event; index += blockDim.x) {
    const auto s {velo_states.get(event_tracks_offset + index)};
    parameters.dev_pvtrack_unsorted_z[event_tracks_offset + index] = s.z;
  }

  __syncthreads();

  // Insert in order
  for (unsigned index = threadIdx.x; index < number_of_tracks_event; index += blockDim.x) {
    const auto z = parameters.dev_pvtrack_unsorted_z[event_tracks_offset + index];
    unsigned insert_position = 0;

    for (unsigned other = 0; other < number_of_tracks_event; ++other) {
      const auto other_z = parameters.dev_pvtrack_unsorted_z[event_tracks_offset + other];
      insert_position += z > other_z || (z == other_z && index > other);
    }

    const auto s = velo_states.get_kalman_state(event_tracks_offset + index);
    parameters.dev_pvtracks[event_tracks_offset + insert_position] = PVTrack {s};
    parameters.dev_pvtrack_z[event_tracks_offset + index] = z;
  }
}
