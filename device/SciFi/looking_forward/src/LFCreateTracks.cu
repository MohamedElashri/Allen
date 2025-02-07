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
#include "LFCreateTracks.cuh"

INSTANTIATE_ALGORITHM(lf_create_tracks::lf_create_tracks_t)

void lf_create_tracks::lf_create_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_scifi_lf_tracks_t>(
    arguments, first<host_number_of_reconstructed_input_tracks_t>(arguments) * m_max_triplets_per_input_track);
  set_size<dev_scifi_lf_atomics_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_scifi_lf_total_number_of_found_triplets_t>(
    arguments, first<host_number_of_reconstructed_input_tracks_t>(arguments));
  set_size<dev_scifi_lf_parametrization_t>(
    arguments, 4 * first<host_number_of_reconstructed_input_tracks_t>(arguments) * m_max_triplets_per_input_track);
}

void lf_create_tracks::lf_create_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_lf_total_number_of_found_triplets_t>(arguments, 0, context);
  Allen::memset_async<dev_scifi_lf_atomics_t>(arguments, 0, context);

  global_function(lf_triplet_keep_best)(
    dim3(size<dev_event_list_t>(arguments)),
    dim3(warp_size, 128 / warp_size),
    context,
    (128 / warp_size) * m_maximum_number_of_triplets_per_warp * sizeof(SciFi::lf_triplet::t))(
    arguments,
    constants.dev_looking_forward_constants,
    m_max_triplets_per_input_track,
    m_maximum_number_of_triplets_per_warp);

  global_function(lf_calculate_parametrization)(
    dim3(size<dev_event_list_t>(arguments)), m_calculate_parametrization_block_dim, context)(
    arguments, m_max_triplets_per_input_track);

  global_function(lf_extend_tracks)(dim3(size<dev_event_list_t>(arguments)), m_extend_tracks_block_dim, context)(
    arguments,
    constants.dev_looking_forward_constants,
    m_max_triplets_per_input_track,
    m_uv_hits_chi2_factor_y,
    m_uv_hits_chi2_factor_x,
    m_chi2_max_extrapolation_to_x_layers_single);
}
