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
#include "UTCopyTrackHitNumber.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(ut_copy_track_hit_number::ut_copy_track_hit_number_t)

void ut_copy_track_hit_number::ut_copy_track_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_offsets_ut_track_hit_number_t>(arguments, first<host_number_of_ut_track_hits_t>(arguments) + 1);
  set_size<host_accumulated_number_of_hits_in_ut_tracks_t>(arguments, 1);
}

void ut_copy_track_hit_number::ut_copy_track_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(ut_copy_track_hit_number)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(
    arguments);

  PrefixSum::prefix_sum<dev_offsets_ut_track_hit_number_t, host_accumulated_number_of_hits_in_ut_tracks_t>(
    *this, arguments, context);
}

/**
 * @brief Copies UT track hit numbers on a consecutive container
 */
__global__ void ut_copy_track_hit_number::ut_copy_track_hit_number(ut_copy_track_hit_number::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto input_offset = parameters.dev_ut_track_selected_offset[event_number];
  const auto output_offset = parameters.dev_ut_track_hits_offset[event_number];
  const auto input_size = parameters.dev_ut_track_hits_offset[event_number + 1] - output_offset;
  const auto input_tracks = parameters.dev_ut_track_hits + input_offset;
  auto output_tracks = parameters.dev_offsets_ut_track_hit_number + output_offset;

  // Loop over tracks.
  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    output_tracks[i] = input_tracks[i].hits_num;
  }
}
