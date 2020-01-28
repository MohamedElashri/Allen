#include "OneTrackMVALine.cuh"

__device__ bool OneTrackMVA::OneTrackMVA(const ParKalmanFilter::FittedTrack& track)
{
  float ptShift = (track.pt() - alpha) / Gaudi::Units::GeV;
  bool decision = track.chi2 / track.ndof < maxChi2Ndof;
  decision &=
    ((ptShift > maxPt && track.ipChi2 > minIPChi2) ||
     (ptShift > minPt && ptShift < maxPt &&
      logf(track.ipChi2) >
        param1 / (ptShift - param2) / (ptShift - param2) + param3 / maxPt * (maxPt - ptShift) + logf(minIPChi2)));
  return decision;
}
