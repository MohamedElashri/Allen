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
#include "VeloCopyTrackHitNumber.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(velo_copy_track_hit_number::velo_copy_track_hit_number_t)

void velo_copy_track_hit_number::velo_copy_track_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<host_number_of_reconstructed_velo_tracks_t>(arguments, 1);

  // Note: Size is "+ 1" due to it storing offsets.
  set_size<dev_offsets_all_velo_tracks_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<dev_offsets_velo_track_hit_number_t>(
    arguments,
    first<host_number_of_velo_tracks_at_least_four_hits_t>(arguments) +
      first<host_number_of_three_hit_tracks_filtered_t>(arguments) + 1);
  set_size<host_accumulated_number_of_hits_in_velo_tracks_t>(arguments, 1);
}

void velo_copy_track_hit_number::velo_copy_track_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_offsets_all_velo_tracks_t>(arguments, 0, context);

  global_function(velo_copy_track_hit_number)(first<host_number_of_events_t>(arguments), m_block_dim, context)(
    arguments);

  *data<host_number_of_reconstructed_velo_tracks_t>(arguments) =
    size<dev_offsets_velo_track_hit_number_t>(arguments) - 1;

  PrefixSum::prefix_sum<dev_offsets_velo_track_hit_number_t, host_accumulated_number_of_hits_in_velo_tracks_t>(
    *this, arguments, context);

  if (m_verbosity >= logger::debug) {
    print<dev_offsets_all_velo_tracks_t>(arguments);
  }
}

/**
 * @brief Copies Velo track hit numbers on a consecutive container
 */
__global__ void velo_copy_track_hit_number::velo_copy_track_hit_number(
  velo_copy_track_hit_number::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const unsigned tracks_offset = Velo::track_offset(parameters.dev_offsets_estimated_input_size, event_number);
  const auto event_tracks = parameters.dev_tracks + tracks_offset;
  const auto number_of_tracks =
    parameters.dev_offsets_velo_tracks[event_number + 1] - parameters.dev_offsets_velo_tracks[event_number];
  const auto number_of_three_hit_tracks = parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1] -
                                          parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];

  // Pointer to velo_track_hit_number of current event
  const auto accumulated_tracks = parameters.dev_offsets_velo_tracks[event_number] +
                                  parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];
  unsigned* velo_track_hit_number = parameters.dev_offsets_velo_track_hit_number + accumulated_tracks;

  for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    velo_track_hit_number[i] = event_tracks[i].hitsNum;
  }

  for (unsigned i = threadIdx.x; i < number_of_three_hit_tracks; i += blockDim.x) {
    velo_track_hit_number[number_of_tracks + i] = 3;
  }

  if (threadIdx.x == 0) {
    parameters.dev_offsets_all_velo_tracks[event_number + 1] =
      parameters.dev_offsets_velo_tracks[event_number + 1] +
      parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1];
  }
}
