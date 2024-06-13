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

#include "DownstreamUTFilter.cuh"

/**
 * @file DownstreamUTFilter.cu
 * @brief This file implements the UT hits filter algorithm, which filters the used UT hits in the VeloUT tracking
 * algorithm and creates a new UT hit container to store all filtered UT hits.
 */

INSTANTIATE_ALGORITHM(downstream_ut_filter::downstream_ut_filter_t);

void downstream_ut_filter::downstream_ut_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Hits
  set_size<dev_filtered_hits_t>(
    arguments, first<host_total_number_of_filtered_hits_t>(arguments) * UT::Hits::element_size);
}

void downstream_ut_filter::downstream_ut_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Reset the counter
  Allen::memset_async<dev_filtered_hits_t>(arguments, 0, context);

  const auto dev_unique_x_sector_layer_offsets = constants.dev_unique_x_sector_layer_offsets.data();

  // Create table
  global_function(downstream_ut_filter)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, dev_unique_x_sector_layer_offsets);
}

__global__ void downstream_ut_filter::downstream_ut_filter(
  downstream_ut_filter::Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets)
{

  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Load UT information
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits};

  // Prepare output
  const auto new_total_num_hits = parameters.dev_filtered_hits_offsets[number_of_events * number_of_unique_x_sectors];
  UT::Hits output_hits {parameters.dev_filtered_hits, new_total_num_hits};
  const UT::HitOffsets new_offsets {
    parameters.dev_filtered_hits_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};

  // Copy unused hits
  for (unsigned sector_idx = threadIdx.x; sector_idx < number_of_unique_x_sectors; sector_idx += blockDim.x) {
    const auto old_sector_hit_offset = ut_hit_offsets.sector_group_offset(sector_idx);
    const auto old_num_hits_in_sector = ut_hit_offsets.sector_group_number_of_hits(sector_idx);
    const auto new_sector_hit_offset = new_offsets.sector_group_offset(sector_idx);
    const auto new_num_hits_in_sector = new_offsets.sector_group_number_of_hits(sector_idx);

    for (unsigned old_idx = 0, new_idx = 0; old_idx < old_num_hits_in_sector && new_idx < new_num_hits_in_sector;
         old_idx++) {
      const auto new_global_idx = new_sector_hit_offset + new_idx;
      const auto old_global_idx = old_sector_hit_offset + old_idx;

      if (parameters.dev_used_ut_hits[old_global_idx]) continue;

      output_hits.yBegin(new_global_idx) = ut_hits.yBegin(old_global_idx);
      output_hits.yEnd(new_global_idx) = ut_hits.yEnd(old_global_idx);
      output_hits.zAtYEq0(new_global_idx) = ut_hits.zAtYEq0(old_global_idx);
      output_hits.xAtYEq0(new_global_idx) = ut_hits.xAtYEq0(old_global_idx);
      output_hits.weight(new_global_idx) = ut_hits.weight(old_global_idx);
      output_hits.id(new_global_idx) = ut_hits.id(old_global_idx);

      new_idx++;
    }
  }
  __syncthreads();
}
