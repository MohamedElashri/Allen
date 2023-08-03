/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "TTrackCosmicLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(t_track_cosmic_line::t_track_cosmic_line_t, t_track_cosmic_line::Parameters)

__device__ bool t_track_cosmic_line::t_track_cosmic_line_t::select(
  const Parameters& parameters,
  std::tuple<const SciFi::Seeding::Track> input)
{
  const SciFi::Seeding::Track& track = std::get<0>(input);
  return (track.chi2X < parameters.max_chi2X) && (track.chi2Y < parameters.max_chi2Y);
}
