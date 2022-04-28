/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "LowPtMuonLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(low_pt_muon_line::low_pt_muon_line_t, low_pt_muon_line::Parameters)

__device__ bool low_pt_muon_line::low_pt_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto track = std::get<0>(input);
  return track.is_muon() && track.ip() >= parameters.minIP && track.ip_chi2() >= parameters.minIPChi2 &&
    track.state().pt() >= parameters.minPt &&
    track.state().chi2() / track.state().ndof() <= parameters.maxChi2Ndof && track.pv().position.z >= parameters.minBPVz;
}
