/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "MomentumBremCorrection.cuh"

INSTANTIATE_ALGORITHM(momentum_brem_correction::momentum_brem_correction_t)

void momentum_brem_correction::momentum_brem_correction_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_brem_corrected_p_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_brem_corrected_pt_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void momentum_brem_correction::momentum_brem_correction_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_brem_corrected_p_t>(arguments, 0, context);
  Allen::memset_async<dev_brem_corrected_pt_t>(arguments, 0, context);

  auto dev_hist_Eop = m_hist_Eop.data(context);
  auto dev_hist_Eop_hasBrem = m_hist_Eop_hasBrem.data(context);
  auto dev_hist_brem = m_hist_brem.data(context);

  global_function(momentum_brem_correction)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, min_bremeop, dev_hist_Eop, dev_hist_Eop_hasBrem, dev_hist_brem);
}

__global__ void momentum_brem_correction::momentum_brem_correction(
  momentum_brem_correction::Parameters parameters,
  const float min_bremeop,
  Allen::Monitoring::Histogram<>::DeviceType hist_Eop,
  Allen::Monitoring::Histogram<>::DeviceType hist_Eop_hasBrem,
  Allen::Monitoring::Histogram<>::DeviceType hist_brem)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto event_long_tracks = parameters.dev_long_tracks_view->container(event_number);

  // Kalman fitted tracks.
  const ParKalmanFilter::FittedTrack* event_tracks =
    parameters.dev_kf_tracks + parameters.dev_track_offsets[event_number];

  const unsigned n_long_tracks = event_long_tracks.size();
  // Loop over tracks.
  for (unsigned i_track = threadIdx.x; i_track < n_long_tracks; i_track += blockDim.x) {

    const auto track = event_tracks[i_track];

    const auto long_track = event_long_tracks.track(i_track);

    const auto eop = parameters.dev_track_Eop[i_track + parameters.dev_track_offsets[event_number]];
    hist_Eop.increment(eop);

    const auto velo_track = long_track.track_segment<Allen::Views::Physics::Track::segment::velo>();
    const auto velo_track_index_with_offset =
      velo_track.track_index() + parameters.dev_velo_tracks_offsets[event_number];

    parameters.dev_brem_corrected_p[i_track + parameters.dev_track_offsets[event_number]] =
      track.p() + parameters.dev_brem_E[velo_track_index_with_offset];
    parameters.dev_brem_corrected_pt[i_track + parameters.dev_track_offsets[event_number]] =
      track.pt() + parameters.dev_brem_ET[velo_track_index_with_offset];

    // E_brem / (E_brem + P_track)
    const auto brem_frac =
      1.f - 1.f / (fabsf(long_track.qop()) *
                   parameters.dev_brem_corrected_p[i_track + parameters.dev_track_offsets[event_number]]);
    hist_brem.increment(brem_frac);

    if (brem_frac > min_bremeop) hist_Eop_hasBrem.increment(eop);
  }
}
