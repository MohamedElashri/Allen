/*****************************************************************************\
 * (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_MinimumBiasLine.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"

// Explicit instantiation of the line
INSTANTIATE_LINE(SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t, SMOG2_minimum_bias_line::Parameters)

// Offset function
__device__ unsigned SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::offset(
  const Parameters& parameters,
  const unsigned event_number)
{
  return parameters.dev_tracks_container[event_number].offset();
}

// Get decision size function
unsigned SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::get_decisions_size(
  const ArgumentReferences<Parameters>& arguments)
{
  return first<host_number_of_reconstructed_velo_tracks_t>(arguments);
}

__device__ unsigned SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::input_size(
  const Parameters& parameters,
  const unsigned event_number)
{
  return parameters.dev_tracks_container[event_number].size();
}

// Get input function
__device__ std::tuple<const unsigned, const float> SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{

  const auto velo_track = parameters.dev_tracks_container[event_number].track(i);
  const auto velo_state = velo_track.state(parameters.dev_velo_states_view[event_number]);
  return std::forward_as_tuple(velo_track.number_of_hits(), velo_state.z());
}

// Selection function
__device__ bool SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned, const float> input)
{
  const auto& velo_track_hit_number = std::get<0>(input);
  const auto& velo_track_state_z = std::get<1>(input);

  return velo_track_state_z < parameters.maxZ && velo_track_state_z >= parameters.minZ &&
         velo_track_hit_number >= parameters.minNHits;
}
