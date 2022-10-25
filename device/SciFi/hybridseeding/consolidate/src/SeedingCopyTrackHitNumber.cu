/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SeedingCopyTrackHitNumber.cuh"

INSTANTIATE_ALGORITHM(seeding_copy_track_hit_number::seeding_copy_track_hit_number_t);

void seeding_copy_track_hit_number::seeding_copy_track_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_seeding_track_hit_number_t>(
    arguments,
    first<host_number_of_reconstructed_seeding_tracks_t>(
      arguments)); // number of reconstructed tracks comes from prefix sum here
}

void seeding_copy_track_hit_number::seeding_copy_track_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(seeding_copy_track_hit_number)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

/**
 * @brief Copies SciFi seeding track hit numbers on a consecutive container
 */
__global__ void seeding_copy_track_hit_number::seeding_copy_track_hit_number(
  seeding_copy_track_hit_number::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto event_tracks = parameters.dev_seeding_tracks + event_number * SciFi::Constants::Nmax_seeds;
  const auto accumulated_tracks = parameters.dev_seeding_atomics[event_number]; // FISHY
  const auto number_of_tracks =
    parameters.dev_seeding_atomics[event_number + 1] - parameters.dev_seeding_atomics[event_number];

  // Pointer to seeding_track_hit_number of current event.
  unsigned* seeding_track_hit_number = parameters.dev_seeding_track_hit_number + accumulated_tracks;

  // Loop over tracks.
  for (unsigned element = threadIdx.x; element < number_of_tracks; element += blockDim.x) {
    seeding_track_hit_number[element] = event_tracks[element].number_of_hits;
  }
}
