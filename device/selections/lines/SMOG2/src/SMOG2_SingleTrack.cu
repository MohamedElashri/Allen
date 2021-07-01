/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_SingleTrack.cuh"

INSTANTIATE_LINE(SMOG2_singletrack_line::SMOG2_singletrack_line_t, SMOG2_singletrack_line::Parameters)

__device__ bool SMOG2_singletrack_line::SMOG2_singletrack_line_t::select(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input)
{
  const auto& track = std::get<0>(input);
  
  const bool decision = track.bpv_z < parameters.maxBPVz && track.bpv_z >= parameters.minBPVz && track.pt() >= parameters.minPt && track.pt() >= parameters.minP && track.chi2 / track.ndof < parameters.maxChi2Ndof;
  return decision;
}
