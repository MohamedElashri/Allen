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

  const auto ptShift = (track.state().pt() - parameters.alpha) / Gaudi::Units::GeV;
  const auto maxPt_GeV = parameters.maxPt / Gaudi::Units::GeV;
  const auto minPt_GeV = parameters.minPt / Gaudi::Units::GeV;
  const auto ipChi2 = track.ip_chi2();
  const bool decision =
    track.state().chi2() / track.state().ndof() < parameters.maxChi2Ndof &&
    ((ptShift > maxPt_GeV && ipChi2 > parameters.minIPChi2) ||
     (ptShift > minPt_GeV && ptShift < maxPt_GeV &&
      logf(ipChi2) > parameters.param1 / ((ptShift - parameters.param2) * (ptShift - parameters.param2)) +
                                parameters.param3 / maxPt_GeV * (maxPt_GeV - ptShift) +
                                logf(parameters.minIPChi2)));
  return decision;
}
