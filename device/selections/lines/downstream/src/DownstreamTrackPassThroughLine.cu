/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DownstreamTrackPassThroughLine.cuh"

// Explicit instantiation of the line
INSTANTIATE_LINE(downstream_track_line::downstream_track_line_t, downstream_track_line::Parameters)

__device__ bool downstream_track_line::downstream_track_line_t::select(
  const Parameters&,
  std::tuple<const Allen::Views::Physics::BasicParticle>)

{
  // This is just used to test the downstream reconstruction
  return false;
}
