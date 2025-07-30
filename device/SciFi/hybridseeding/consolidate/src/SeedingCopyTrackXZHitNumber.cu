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
#include "SeedingCopyTrackXZHitNumber.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(seeding_copy_trackXZ_hit_number::seeding_copy_trackXZ_hit_number_t);

void seeding_copy_trackXZ_hit_number::seeding_copy_trackXZ_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_offsets_scifi_seedsXZ_t>(arguments, size<dev_seed_xz_number_of_tracks_t>(arguments) + 1);
  set_size<host_number_of_reconstructed_seeding_tracksXZ_t>(arguments, 1);
  set_size<dev_offsets_scifi_seedXZ_hit_number_t>(arguments, 1); // will be resized
}

void seeding_copy_trackXZ_hit_number::seeding_copy_trackXZ_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::copy_async<dev_offsets_scifi_seedsXZ_t, dev_seed_xz_number_of_tracks_t>(arguments, context);

  PrefixSum::prefix_sum<dev_offsets_scifi_seedsXZ_t, host_number_of_reconstructed_seeding_tracksXZ_t>(
    *this, arguments, context);

  resize<dev_offsets_scifi_seedXZ_hit_number_t>(
    arguments, first<host_number_of_reconstructed_seeding_tracksXZ_t>(arguments) + 1);

  global_function(seeding_copy_trackXZ_hit_number)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments);

  PrefixSum::prefix_sum<dev_offsets_scifi_seedXZ_hit_number_t>(*this, arguments, context);
}

/**
 * @brief Copies SciFi seeding trackXZ hit numbers on a consecutive container
 */
__global__ void seeding_copy_trackXZ_hit_number::seeding_copy_trackXZ_hit_number(
  seeding_copy_trackXZ_hit_number::Parameters parameters)
{
  // FIXME: right now we do not take into account the fact that XZ tracks are stored in [part 0 part 1]
  const auto event_number = blockIdx.x;
  const auto event_tracksXZ = parameters.dev_seeding_tracksXZ + event_number * SciFi::Constants::Nmax_seed_xz; // FIXME
  const auto accumulated_tracksXZ = parameters.dev_offsets_scifi_seedsXZ[event_number];
  const auto number_of_tracksXZ = parameters.dev_offsets_scifi_seedsXZ[event_number + 1] - accumulated_tracksXZ;

  // Pointer to seeding_trackXZ_hit_number of current event.
  unsigned* seeding_trackXZ_hit_number = parameters.dev_offsets_scifi_seedXZ_hit_number + accumulated_tracksXZ;

  // Loop over tracksXZ.
  for (unsigned element = threadIdx.x; element < number_of_tracksXZ; ++element) {
    seeding_trackXZ_hit_number[element] = event_tracksXZ[element].number_of_hits;
  }
}
