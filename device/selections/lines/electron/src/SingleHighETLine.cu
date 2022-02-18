/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SingleHighETLine.cuh"

// Explicit instantiation of the line
INSTANTIATE_LINE(single_high_et_line::single_high_et_line_t, single_high_et_line::Parameters)

// Offset function
__device__ unsigned single_high_et_line::single_high_et_line_t::offset(
  const Parameters& parameters,
  const unsigned event_number)
{
  return parameters.dev_velo_tracks_offsets[event_number];
}

__device__ unsigned single_high_et_line::single_high_et_line_t::input_size(
  const Parameters& parameters,
  const unsigned event_number)
{
  return parameters.dev_velo_tracks_offsets[event_number + 1] - parameters.dev_velo_tracks_offsets[event_number];
}

// Get decision size function
unsigned single_high_et_line::single_high_et_line_t::get_decisions_size(ArgumentReferences<Parameters>& arguments)
{
  return first<typename Parameters::host_number_of_reconstructed_velo_tracks_t>(arguments);
}

// Get input function
__device__ std::tuple<const float> single_high_et_line::single_high_et_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const unsigned track_index = i + parameters.dev_velo_tracks_offsets[event_number];

  return std::forward_as_tuple(parameters.dev_brem_ET[track_index]);
}

// Selection function
__device__ bool single_high_et_line::single_high_et_line_t::select(
  const Parameters& parameters,
  std::tuple<const float> input)
{
  const float calo_ET = std::get<0>(input);

  const bool decision = (calo_ET > parameters.minET);

  return decision;
}
