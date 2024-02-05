/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "SMOG2_SingleMuon.cuh"

// Explicit instantiation
INSTANTIATE_LINE(SMOG2_single_muon_line::SMOG2_single_muon_line_t, SMOG2_single_muon_line::Parameters)

__device__ bool SMOG2_single_muon_line::SMOG2_single_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto track = std::get<0>(input);
  bool decision = track.is_muon() && track.state().pt() > parameters.MinPt && track.state().p() > parameters.MinP &&
                  track.state().chi2() / track.state().ndof() < parameters.maxChi2Ndof &&
                  track.state().z() < parameters.maxBPVz && track.state().z() >= parameters.minBPVz;
  if (track.has_pv()) decision = decision && track.pv().position.z < parameters.maxBPVz;

  return decision;
}
