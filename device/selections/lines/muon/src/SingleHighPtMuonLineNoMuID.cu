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
#include "SingleHighPtMuonLineNoMuID.cuh"

// Explicit instantiation
INSTANTIATE_LINE(
  single_high_pt_muon_no_muid_line::single_high_pt_muon_no_muid_line_t,
  single_high_pt_muon_no_muid_line::Parameters)

__device__ bool single_high_pt_muon_no_muid_line::single_high_pt_muon_no_muid_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto& track = std::get<0>(input);
  const bool decision = track.state().chi2() / track.state().ndof() < properties.maxChi2Ndof &&
                        track.state().pt() > properties.singleMinPt && track.state().p() > properties.singleMinP &&
                        track.state().z() > properties.minZ;

  return decision;
}

__device__ bool single_high_pt_muon_no_muid_line::single_high_pt_muon_no_muid_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::BasicParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) parameters.pt[index] = std::get<0>(input).state().pt();
  return sel;
}
