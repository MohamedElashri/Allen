/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_SingleTrack.cuh"

INSTANTIATE_LINE(SMOG2_singletrack_line::SMOG2_singletrack_line_t, SMOG2_singletrack_line::Parameters)

__device__ bool SMOG2_singletrack_line::SMOG2_singletrack_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto& track = std::get<0>(input);

  bool decision = track.state().pt() >= parameters.minPt && track.state().p() >= parameters.minP &&
    track.chi2() / track.ndof() < parameters.maxChi2Ndof &&
				  track.state().z() < parameters.maxBPVz && track.state().z() >= parameters.minBPVz;
  if (track.has_pv()) decision = decision && track.pv().position.z < parameters.maxBPVz;

  return decision;
}
