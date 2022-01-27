/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "TrackMuonMVALine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(track_muon_mva_line::track_muon_mva_line_t, track_muon_mva_line::Parameters)

__device__ bool track_muon_mva_line::track_muon_mva_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto& track = std::get<0>(input);
  if (!track.is_muon()) {
    return false;
  }

  const auto ptShift = (track.pt() - parameters.alpha);
  const bool decision =
    track.state().chi2() / track.state().ndof() < parameters.maxChi2Ndof &&
    ((ptShift > parameters.maxPt && track.ip_chi2() > parameters.minIPChi2) ||
     (ptShift > parameters.minPt && ptShift < parameters.maxPt &&
      logf(track.ip_chi2()) > parameters.param1 / ((ptShift - parameters.param2) * (ptShift - parameters.param2)) +
                                parameters.param3 / parameters.maxPt * (parameters.maxPt - ptShift) +
                                logf(parameters.minIPChi2)));
  return decision;
}
