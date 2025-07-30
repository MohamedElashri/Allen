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
#include "SMOG2_SingleTrack.cuh"

INSTANTIATE_LINE(SMOG2_singletrack_line::SMOG2_singletrack_line_t, SMOG2_singletrack_line::Parameters)

__device__ bool SMOG2_singletrack_line::SMOG2_singletrack_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto& track = std::get<0>(input);

  bool decision = track.state().pt() >= properties.minPt && track.state().p() >= properties.minP &&
                  track.chi2() / track.ndof() < properties.maxChi2Ndof && track.state().z() < properties.maxBPVz &&
                  track.state().z() >= properties.minBPVz && track.has_pv() &&
                  track.pv().position.z < properties.maxBPVz && track.pv().position.z >= properties.minBPVz &&
                  track.track().ghost_probability() < properties.maxGhostProb;

  return decision;
}
