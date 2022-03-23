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
  return parameters.dev_offsets_velo_tracks[event_number];
}

// Get decision size function
unsigned SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::get_decisions_size(
  ArgumentReferences<Parameters>& arguments)
{
  return first<host_number_of_reconstructed_velo_tracks_t>(arguments);
}

// Get input function
__device__ std::tuple<const unsigned, const float> SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  // Create the velo tracks
  Velo::Consolidated::Tracks const velo_tracks {parameters.dev_offsets_velo_tracks,
                                                parameters.dev_velo_track_hit_number,
                                                event_number,
                                                parameters.dev_number_of_events[0]};

  Velo::Consolidated::ConstStates kalmanvelo_states {parameters.dev_velo_kalman_beamline_states,
                                                     velo_tracks.total_number_of_tracks()};
  const unsigned track_index = parameters.dev_offsets_velo_tracks[event_number] + i;
  const KalmanVeloState state = kalmanvelo_states.get_kalman_state(track_index);
  return std::forward_as_tuple(velo_tracks.number_of_hits(i), state.z);
}

// Selection function
__device__ bool SMOG2_minimum_bias_line::SMOG2_minimum_bias_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned, const float> input)
{
  const auto& velo_track_hit_number = std::get<0>(input);
  const auto& velo_track_state_poca_z = std::get<1>(input);

  const bool decision = velo_track_state_poca_z < parameters.maxZ && velo_track_state_poca_z >= parameters.minZ &&
                        velo_track_hit_number >= parameters.minNHits;
  return decision;
}
