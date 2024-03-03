/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateSeeds.cuh"

#include "Common.h"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include <string>

INSTANTIATE_ALGORITHM(consolidate_seeds::consolidate_seeds_t)

void consolidate_seeds::consolidate_seeds_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_consolidated_interaction_seeds_t>(arguments, first<host_total_number_of_seeds_t>(arguments));
}

void consolidate_seeds::consolidate_seeds_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{

  global_function(consolidate_seeds)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_t>(), context)(
    arguments);
}

__global__ void consolidate_seeds::consolidate_seeds(consolidate_seeds::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Input
  const auto velo_tracks = parameters.dev_velo_track_view[event_number];
  auto event_seeds_input = parameters.dev_interaction_seeds + velo_tracks.offset();

  // Output
  auto event_seeds_tracks_output =
    parameters.dev_consolidated_interaction_seeds + parameters.dev_interaction_seeds_offsets[event_number];
  auto event_number_of_seeds = parameters.dev_number_of_seeds[event_number];
  for (auto i_seeds_track = threadIdx.x; i_seeds_track < event_number_of_seeds; i_seeds_track += blockDim.x)
    event_seeds_tracks_output[i_seeds_track] = event_seeds_input[i_seeds_track];
}
