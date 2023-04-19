/*****************************************************************************\
 * (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "NDisplacedVELOTracksLine.cuh"

INSTANTIATE_LINE(n_displaced_velo_track_line::n_displaced_velo_track_line_t, n_displaced_velo_track_line::Parameters)

__device__ std::tuple<const unsigned> n_displaced_velo_track_line::n_displaced_velo_track_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned)
{
  const auto n_filtered_velo_tracks = parameters.dev_number_of_filtered_tracks[event_number];
  return std::forward_as_tuple(n_filtered_velo_tracks);
}

__device__ bool n_displaced_velo_track_line::n_displaced_velo_track_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned> input)
{
  const auto& n_velo_tracks = std::get<0>(input);
  return n_velo_tracks >= parameters.min_filtered_velo_tracks;
}
