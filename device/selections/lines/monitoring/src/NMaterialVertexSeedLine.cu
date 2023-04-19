/*****************************************************************************\
 * (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "NMaterialVertexSeedLine.cuh"

INSTANTIATE_LINE(n_materialvertex_seed_line::n_materialvertex_seed_line_t, n_materialvertex_seed_line::Parameters)

__device__ std::tuple<const unsigned> n_materialvertex_seed_line::n_materialvertex_seed_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned)
{
  const auto n_vertex_seeds = parameters.dev_number_of_materialvertex_seeds[event_number];
  return std::forward_as_tuple(n_vertex_seeds);
}

__device__ bool n_materialvertex_seed_line::n_materialvertex_seed_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned> input)
{
  const auto& n_vertex_seeds = std::get<0>(input);
  return n_vertex_seeds >= parameters.min_materialvertex_seeds;
}
