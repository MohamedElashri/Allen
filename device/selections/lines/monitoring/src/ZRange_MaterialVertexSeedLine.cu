/*****************************************************************************\
 * (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "ZRange_MaterialVertexSeedLine.cuh"

INSTANTIATE_LINE(
  z_range_materialvertex_seed_line::z_range_materialvertex_seed_line_t,
  z_range_materialvertex_seed_line::Parameters)

// Offset function
__device__ unsigned z_range_materialvertex_seed_line::z_range_materialvertex_seed_line_t::offset(
  const Parameters& parameters,
  const unsigned event_number)
{
  return parameters.dev_interaction_seeds_offsets[event_number];
}

// Get decision size function
unsigned z_range_materialvertex_seed_line::z_range_materialvertex_seed_line_t::get_decisions_size(
  const ArgumentReferences<Parameters>& arguments)
{
  return first<host_total_number_of_interaction_seeds_t>(arguments);
}

__device__ unsigned z_range_materialvertex_seed_line::z_range_materialvertex_seed_line_t::input_size(
  const Parameters& parameters,
  const unsigned event_number)
{
  return parameters.dev_interaction_seeds_offsets[event_number + 1] -
         parameters.dev_interaction_seeds_offsets[event_number];
}

__device__ std::tuple<const float> z_range_materialvertex_seed_line::z_range_materialvertex_seed_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto interaction_seeds_offsets = parameters.dev_interaction_seeds_offsets[event_number];
  const unsigned seed_index = i + interaction_seeds_offsets;

  const auto seeds = parameters.dev_consolidated_interaction_seeds;
  return std::forward_as_tuple(seeds[seed_index].z);
}

__device__ bool z_range_materialvertex_seed_line::z_range_materialvertex_seed_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const float> input)
{
  const auto& vertex_seed_z = std::get<0>(input);
  return vertex_seed_z >= properties.min_z_materialvertex_seed && vertex_seed_z < properties.max_z_materialvertex_seed;
}
