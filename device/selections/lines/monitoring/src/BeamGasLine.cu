/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "BeamGasLine.cuh"
#include "Event/ODIN.h"
#include "ODINBank.cuh"

// Explicit instantiation
INSTANTIATE_LINE(beam_gas_line::beam_gas_line_t, beam_gas_line::Parameters)

__device__ std::tuple<const unsigned, const unsigned, const unsigned, const float>
beam_gas_line::beam_gas_line_t::get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
{
  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];

  const unsigned number_of_velo_tracks = velo_tracks.size();

  const unsigned number_of_velo_hits = (velo_tracks.track(i)).number_of_hits();

  const unsigned* event_odin_data = nullptr;
  if (parameters.dev_mep_layout[0]) {
    event_odin_data =
      odin_data_mep_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
  }
  else {
    event_odin_data =
      odin_data_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
  }

  const unsigned bxt = static_cast<unsigned int>(LHCb::ODIN({event_odin_data, 10}).bunchCrossingType());

  const auto velo_states = parameters.dev_velo_states_view[event_number];

  const float poca_z = (velo_states.state(i)).z();

  return std::forward_as_tuple(number_of_velo_tracks, bxt, number_of_velo_hits, poca_z);
}

__device__ bool beam_gas_line::beam_gas_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned, const unsigned, const unsigned, const float> input)
{
  const auto [number_of_velo_tracks, beam_crossing_number, velo_track_hit_number, velo_track_state_poca_z] = input;
  return number_of_velo_tracks >= parameters.min_velo_tracks && beam_crossing_number == parameters.beam_crossing_type &&
         velo_track_hit_number >= parameters.minNHits && velo_track_state_poca_z > parameters.minZ &&
         velo_track_state_poca_z < parameters.maxZ;
}
