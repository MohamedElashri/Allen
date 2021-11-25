/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "TrackMVALine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(track_mva_line::track_mva_line_t, track_mva_line::Parameters)

__device__ bool track_mva_line::track_mva_line_t::select(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input)
{
  const auto& track = std::get<0>(input);

  const auto ptShift = (track.pt() - parameters.alpha) / Gaudi::Units::GeV;
  const auto maxPt_GeV = parameters.maxPt / Gaudi::Units::GeV;
  const auto minPt_GeV = parameters.minPt / Gaudi::Units::GeV;

  const bool decision =
    track.chi2 / track.ndof < parameters.maxChi2Ndof &&
    ((ptShift > maxPt_GeV && track.ipChi2 > parameters.minIPChi2) ||
     (ptShift > minPt_GeV && ptShift < maxPt_GeV &&
      logf(track.ipChi2) > parameters.param1 / ((ptShift - parameters.param2) * (ptShift - parameters.param2)) +
                             (parameters.param3 / maxPt_GeV) * (maxPt_GeV - ptShift) + logf(parameters.minIPChi2)));
  return decision;
}
