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

  const auto ptShift = (track.pt() - parameters.alpha);
  const auto maxPt = parameters.maxPt;
  const auto minIPChi2 = parameters.minIPChi2;
  const auto trackIPChi2 = track.ipChi2;

  const bool decision =
    track.chi2 / track.ndof < parameters.maxChi2Ndof &&
    ((ptShift > maxPt && trackIPChi2 > minIPChi2) ||
     (ptShift > parameters.minPt && ptShift < maxPt &&
      logf(trackIPChi2) > parameters.param1 / ((ptShift - parameters.param2) * (ptShift - parameters.param2)) +
                            (parameters.param3 / maxPt) * (maxPt - ptShift) + logf(minIPChi2)));
  return decision;
}
