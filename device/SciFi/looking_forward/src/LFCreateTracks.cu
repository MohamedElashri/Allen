/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LFCreateTracks.cuh"

INSTANTIATE_ALGORITHM(lf_create_tracks::lf_create_tracks_t)

void lf_create_tracks::lf_create_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_scifi_lf_tracks_t>(
    arguments,
    first<host_number_of_reconstructed_input_tracks_t>(arguments) * property<max_triplets_per_input_track_t>());
  set_size<dev_scifi_lf_atomics_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_scifi_lf_total_number_of_found_triplets_t>(
    arguments, first<host_number_of_reconstructed_input_tracks_t>(arguments));
  set_size<dev_scifi_lf_parametrization_t>(
    arguments,
    4 * first<host_number_of_reconstructed_input_tracks_t>(arguments) * property<max_triplets_per_input_track_t>());
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
    (128 / warp_size) * property<maximum_number_of_triplets_per_warp_t>() *
      sizeof(SciFi::lf_triplet::t))(arguments, constants.dev_looking_forward_constants);

  global_function(lf_calculate_parametrization)(
    dim3(size<dev_event_list_t>(arguments)), property<calculate_parametrization_block_dim_t>(), context)(
    arguments, constants.dev_looking_forward_constants);

  global_function(lf_extend_tracks)(
    dim3(size<dev_event_list_t>(arguments)), property<extend_tracks_block_dim_t>(), context)(
    arguments, constants.dev_looking_forward_constants);
}
