/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ParKalmanVeloOnly.cuh"

INSTANTIATE_ALGORITHM(package_kalman_tracks::package_kalman_tracks_t)

void package_kalman_tracks::package_kalman_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_kf_tracks_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void package_kalman_tracks::package_kalman_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(package_kalman_tracks)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

__global__ void package_kalman_tracks::package_kalman_tracks(package_kalman_tracks::Parameters parameters)
{
  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;

  // Long tracks.
  const auto event_long_tracks = parameters.dev_long_tracks_view->container(event_number);
  const unsigned n_long_tracks = parameters.dev_long_tracks_view->number_of_contained_objects();

  // Create velo tracks.
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  for (unsigned i_long_track = threadIdx.x; i_long_track < n_long_tracks; i_long_track += blockDim.x) {
    // Prepare fit input.
    const auto long_track = event_long_tracks.track(i_long_track);
    const auto velo_track = long_track.track_segment<Allen::Views::Physics::Track::segment::velo>();
    Velo::Consolidated::ConstStates kalmanvelo_states {parameters.dev_velo_kalman_beamline_states,
                                                       velo_tracks.total_number_of_tracks()};
    parameters.dev_kf_tracks[event_long_tracks.offset() + i_long_track] = ParKalmanFilter::FittedTrack {
      kalmanvelo_states.get_kalman_state(velo_tracks.tracks_offset(event_number) + velo_track.track_index()),
      long_track.qop(),
      parameters.dev_is_muon[event_long_tracks.offset() + i_long_track]};
  }
}