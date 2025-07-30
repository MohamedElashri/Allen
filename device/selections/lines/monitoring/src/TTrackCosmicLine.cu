/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TTrackCosmicLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(t_track_cosmic_line::t_track_cosmic_line_t, t_track_cosmic_line::Parameters)

__device__ bool t_track_cosmic_line::t_track_cosmic_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const SciFi::Seeding::Track> input)
{
  const SciFi::Seeding::Track& track = std::get<0>(input);
  return (track.chi2X < properties.max_chi2X) && (track.chi2Y < properties.max_chi2Y);
}
