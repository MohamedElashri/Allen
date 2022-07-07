/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "MomentumBremCorrection.cuh"

INSTANTIATE_ALGORITHM(momentum_brem_correction::momentum_brem_correction_t)

void momentum_brem_correction::momentum_brem_correction_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_brem_corrected_p_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_brem_corrected_pt_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void momentum_brem_correction::momentum_brem_correction_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_brem_corrected_p_t>(arguments, 0, context);
  Allen::memset_async<dev_brem_corrected_pt_t>(arguments, 0, context);

  global_function(momentum_brem_correction)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void momentum_brem_correction::momentum_brem_correction(momentum_brem_correction::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Kalman fitted tracks.
  const ParKalmanFilter::FittedTrack* event_tracks =
    parameters.dev_kf_tracks + parameters.dev_track_offsets[event_number];
  const auto N_tracks = parameters.dev_track_offsets[event_number + 1] - parameters.dev_track_offsets[event_number];

  // Loop over tracks.
  for (unsigned i_track = threadIdx.x; i_track < N_tracks; i_track += blockDim.x) {

    const auto track = event_tracks[i_track];

    const unsigned UT_track_index =
      parameters.dev_scifi_tracks_ut_indices[i_track + parameters.dev_track_offsets[event_number]];

    const auto velo_track_index_with_offset =
      parameters.dev_ut_tracks_velo_indices[UT_track_index + parameters.dev_ut_tracks_offsets[event_number]] +
      parameters.dev_velo_tracks_offsets[event_number];

    parameters.dev_brem_corrected_p[i_track + parameters.dev_track_offsets[event_number]] =
      track.p() + parameters.dev_brem_E[velo_track_index_with_offset];
    parameters.dev_brem_corrected_pt[i_track + parameters.dev_track_offsets[event_number]] =
      track.pt() + parameters.dev_brem_ET[velo_track_index_with_offset];
  }
}
