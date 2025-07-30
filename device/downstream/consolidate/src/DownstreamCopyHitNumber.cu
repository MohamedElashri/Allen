/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DownstreamCopyHitNumber.cuh"
#include <PrefixSum.cuh>

/**
 * @file DownstreamCopyHitNumber.cu
 * @brief Copy the number of hits per track from the downstream tracks to the
 * downstream track hit number array.
 * @details This algorithm is used to copy the number of hits per track from the
 * downstream tracks to the downstream track hit number array. This is needed to be
 * able to copy the downstream tracks to the host.
 */

INSTANTIATE_ALGORITHM(downstream_copy_hit_number::downstream_copy_hit_number_t)

void downstream_copy_hit_number::downstream_copy_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_offsets_downstream_hit_numbers_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments) + 1);
  set_size<host_number_of_hits_in_downstream_tracks_t>(arguments, 1);
}

void downstream_copy_hit_number::downstream_copy_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(downstream_copy_hit_number)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(
    arguments);

  PrefixSum::prefix_sum<dev_offsets_downstream_hit_numbers_t, host_number_of_hits_in_downstream_tracks_t>(
    *this, arguments, context);
}

__global__ void downstream_copy_hit_number::downstream_copy_hit_number(
  downstream_copy_hit_number::Parameters parameters)
{
  // Basic
  const auto event_number = blockIdx.x;
  // Tracks
  auto downstream_tracks = parameters.dev_downstream_tracks + event_number * UT::Constants::max_num_tracks;
  const auto downstream_tracks_offset = parameters.dev_offsets_downstream_tracks[event_number];
  const auto downstream_tracks_size =
    parameters.dev_offsets_downstream_tracks[event_number + 1] - downstream_tracks_offset;

  // Output
  auto downstream_track_hit_number = parameters.dev_offsets_downstream_hit_numbers + downstream_tracks_offset;

  // Loop over tracks.
  for (unsigned idx = threadIdx.x; idx < downstream_tracks_size; idx += blockDim.x) {
    downstream_track_hit_number[idx] = downstream_tracks[idx].num_hits;
  }
}
