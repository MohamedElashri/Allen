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
