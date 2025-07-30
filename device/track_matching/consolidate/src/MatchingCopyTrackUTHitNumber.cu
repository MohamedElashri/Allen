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
#include "MatchingCopyTrackUTHitNumber.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(matching_copy_track_ut_hit_number::matching_copy_track_ut_hit_number_t);

void matching_copy_track_ut_hit_number::matching_copy_track_ut_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_offsets_matched_ut_hit_number_t>(
    arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments) + 1);
  set_size<host_total_sum_holder_t>(arguments, 1);
}

void matching_copy_track_ut_hit_number::matching_copy_track_ut_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(matching_copy_track_ut_hit_number)(
    dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(arguments);

  PrefixSum::prefix_sum<dev_offsets_matched_ut_hit_number_t, host_total_sum_holder_t>(*this, arguments, context);
}

/**
 * @brief Copies UT track hit numbers on a consecutive container
 */
__global__ void matching_copy_track_ut_hit_number::matching_copy_track_ut_hit_number(
  matching_copy_track_ut_hit_number::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto event_tracks = parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;
  const auto accumulated_tracks = parameters.dev_offsets_matched_tracks[event_number];
  const auto number_of_tracks =
    parameters.dev_offsets_matched_tracks[event_number + 1] - parameters.dev_offsets_matched_tracks[event_number];

  // Pointer to ut_track_hit_number of current event.
  unsigned* matched_track_hit_number = parameters.dev_offsets_matched_ut_hit_number + accumulated_tracks;

  // Loop over tracks.
  for (unsigned element = threadIdx.x; element < number_of_tracks; element += blockDim.x) {
    matched_track_hit_number[element] = event_tracks[element].number_of_hits_ut;
  }
}
