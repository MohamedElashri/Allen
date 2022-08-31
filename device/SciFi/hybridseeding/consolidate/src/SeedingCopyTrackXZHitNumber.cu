/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SeedingCopyTrackXZHitNumber.cuh"

INSTANTIATE_ALGORITHM(seeding_copy_trackXZ_hit_number::seeding_copy_trackXZ_hit_number_t);

void seeding_copy_trackXZ_hit_number::seeding_copy_trackXZ_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_seeding_trackXZ_hit_number_t>(
    arguments,
    first<host_number_of_reconstructed_seeding_tracksXZ_t>(
      arguments)); // number of reconstructed tracksXZ comes from prefix sum here
}

void seeding_copy_trackXZ_hit_number::seeding_copy_trackXZ_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(seeding_copy_trackXZ_hit_number)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
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
  const auto accumulated_tracksXZ = parameters.dev_seeding_xz_atomics[event_number];                           // FISHY
  const auto number_of_tracksXZ =
    parameters.dev_seeding_xz_atomics[event_number + 1] - parameters.dev_seeding_xz_atomics[event_number]; // FISHY

  // Pointer to seeding_trackXZ_hit_number of current event.
  unsigned* seeding_trackXZ_hit_number = parameters.dev_seeding_trackXZ_hit_number + accumulated_tracksXZ;

  // Loop over tracksXZ.
  for (unsigned element = threadIdx.x; element < number_of_tracksXZ; ++element) {
    seeding_trackXZ_hit_number[element] = event_tracksXZ[element].number_of_hits;
  }
}
