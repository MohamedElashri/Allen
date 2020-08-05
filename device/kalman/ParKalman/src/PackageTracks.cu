/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ParKalmanVeloOnly.cuh"

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
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(package_kalman_tracks)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);
}

__global__ void package_kalman_tracks::package_kalman_tracks(package_kalman_tracks::Parameters parameters)
{
  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;

  // Create velo tracks.
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  // Create UT tracks.
  UT::Consolidated::ConstExtendedTracks ut_tracks {
    parameters.dev_atomics_ut,
    parameters.dev_ut_track_hit_number,
    parameters.dev_ut_qop,
    parameters.dev_ut_track_velo_indices,
    event_number,
    number_of_events};

  // Create SciFi tracks.
  SciFi::Consolidated::ConstTracks scifi_tracks {
    parameters.dev_atomics_scifi,
    parameters.dev_scifi_track_hit_number,
    parameters.dev_scifi_qop,
    parameters.dev_scifi_states,
    parameters.dev_scifi_track_ut_indices,
    event_number,
    number_of_events};

  const unsigned n_scifi_tracks = scifi_tracks.number_of_tracks(event_number);
  for (unsigned i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    // Prepare fit input.
    const int i_ut_track = scifi_tracks.ut_track(i_scifi_track);
    const int i_velo_track = ut_tracks.velo_track(i_ut_track);
    Velo::Consolidated::ConstStates kalmanvelo_states {
      parameters.dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks()};
    parameters.dev_kf_tracks[scifi_tracks.tracks_offset(event_number) + i_scifi_track] = ParKalmanFilter::FittedTrack {
      kalmanvelo_states.get_kalman_state(velo_tracks.tracks_offset(event_number) + i_velo_track),
      scifi_tracks.qop(i_scifi_track),
      parameters.dev_is_muon[scifi_tracks.tracks_offset(event_number) + i_scifi_track]};
  }
}