/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "VeloClustersMicroBiasLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(
  velo_clusters_micro_bias_line::velo_clusters_micro_bias_line_t,
  velo_clusters_micro_bias_line::Parameters)

__device__ std::tuple<const unsigned> velo_clusters_micro_bias_line::velo_clusters_micro_bias_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned)
{
  const unsigned* module_pair_hit_start =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_module_pairs;
  const unsigned event_number_of_hits =
    module_pair_hit_start[Velo::Constants::n_module_pairs] - module_pair_hit_start[0];

  return std::forward_as_tuple(event_number_of_hits);
}

__device__ bool velo_clusters_micro_bias_line::velo_clusters_micro_bias_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned> input)
{
  const auto number_of_velo_clusters = std::get<0>(input);
  return number_of_velo_clusters >= parameters.min_velo_clusters;
}
