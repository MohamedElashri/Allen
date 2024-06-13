/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DownstreamUpdateUTOffset.cuh"

/**
 * @file DownstreamUpdateUTOffset.cu
 * @brief This file implements the algorithm that updates the UT hit offsets for filtered UT hits. This is necessary
 * because VeloUT tracking is not a zero-ghost algorithm. Some UT hits may be used in more than one VeloUT track, so the
 * new offsets for filtered UT hits cannot be simply calculated by subtracting the number of used UT hits.
 */

INSTANTIATE_ALGORITHM(downstream_update_ut_offset::downstream_update_ut_offset_t);

void downstream_update_ut_offset::downstream_update_ut_offset_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants& constants) const
{
  // Offsets
  set_size<dev_num_hits_per_sector_t>(
    arguments,
    first<host_number_of_events_t>(arguments) *
      (constants.host_unique_x_sector_layer_offsets[UT::Constants::n_layers]));
}

void downstream_update_ut_offset::downstream_update_ut_offset_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // // Reset the counter
  Allen::memset_async<dev_num_hits_per_sector_t>(arguments, 0, context);

  // Create table
  global_function(downstream_update_ut_offset)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_unique_x_sector_layer_offsets.data());
}

__global__ void downstream_update_ut_offset::downstream_update_ut_offset(
  downstream_update_ut_offset::Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Load UT information
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};

  // Prepare output
  auto output_num_hits_per_sector =
    parameters.dev_num_hits_per_sector + event_number * dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];

  // Calculate number of hits in each sector
  for (unsigned sector_idx = threadIdx.x; sector_idx < number_of_unique_x_sectors; sector_idx += blockDim.x) {
    unsigned num_hits_in_each_sector = 0;
    const auto sector_hit_offset = ut_hit_offsets.sector_group_offset(sector_idx);
    const auto num_hits_in_sector = ut_hit_offsets.sector_group_number_of_hits(sector_idx);
    for (unsigned hit_idx = 0; hit_idx < num_hits_in_sector; hit_idx++) {
      if (parameters.dev_used_ut_hits[sector_hit_offset + hit_idx]) continue;
      num_hits_in_each_sector++;
    }
    output_num_hits_per_sector[sector_idx] = num_hits_in_each_sector;
  }
  __syncthreads();
}
