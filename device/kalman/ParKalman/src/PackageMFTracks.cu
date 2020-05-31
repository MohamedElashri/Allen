/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ParKalmanVeloOnly.cuh"
#include "PackageMFTracks.cuh"

void package_mf_tracks::package_mf_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_mf_tracks_t>(arguments, first<host_number_of_mf_tracks_t>(arguments));
}

void package_mf_tracks::package_mf_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  initialize<dev_mf_tracks_t>(arguments, 0, stream);

  global_function(package_mf_tracks)(
    dim3(first<host_selected_events_mf_t>(arguments)), property<block_dim_t>(), stream)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void package_mf_tracks::package_mf_tracks(
  package_mf_tracks::Parameters parameters,
  const unsigned number_of_events)
{
  const unsigned muon_filtered_event = blockIdx.x;
  const unsigned i_event = parameters.dev_event_list_mf[muon_filtered_event];

  // Create velo tracks.
  const Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, i_event, number_of_events};

  // Create UT tracks.
  UT::Consolidated::ConstExtendedTracks ut_tracks {
    parameters.dev_atomics_ut,
    parameters.dev_ut_track_hit_number,
    parameters.dev_ut_qop,
    parameters.dev_ut_track_velo_indices,
    i_event,
    number_of_events};

  const unsigned mf_track_offset = parameters.dev_mf_track_offsets[i_event];
  ParKalmanFilter::FittedTrack* event_mf_tracks = parameters.dev_mf_tracks + mf_track_offset;

  for (unsigned i_ut_track = threadIdx.x; i_ut_track < ut_tracks.number_of_tracks(i_event); i_ut_track += blockDim.x) {

    const int i_velo_track = ut_tracks.velo_track(i_ut_track);
    Velo::Consolidated::ConstKalmanStates kalmanvelo_states {
      parameters.dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks()};
    const KalmanVeloState velo_state = kalmanvelo_states.get(velo_tracks.tracks_offset(i_event) + i_velo_track);
    event_mf_tracks[i_ut_track] = ParKalmanFilter::FittedTrack {
      velo_state,
      ut_tracks.qop(i_ut_track),
      parameters.dev_match_upstream_muon[ut_tracks.tracks_offset(i_event) + i_ut_track]};
  }
}