/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "LowPtMuonLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(low_pt_muon_line::low_pt_muon_line_t, low_pt_muon_line::Parameters)

__device__ bool low_pt_muon_line::low_pt_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input) const
{
  const auto& track = std::get<0>(input);
  return track.is_muon && track.ip >= parameters.minIP && track.ipChi2 >= parameters.minIPChi2 &&
         track.pt() >= parameters.minPt && track.chi2 / track.ndof <= parameters.maxChi2Ndof;
}
