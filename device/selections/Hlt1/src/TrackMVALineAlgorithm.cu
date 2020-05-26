#include "TrackMVALineAlgorithm.cuh"

__device__ bool track_mva_line_algorithm::track_mva_line_algorithm_t::doline(
  const Parameters& ps,
  const ParKalmanFilter::FittedTrack& track) const
{
  const auto ptShift = (track.pt() - ps.alpha) / Gaudi::Units::GeV;
  const bool decision = track.chi2 / track.ndof < ps.maxChi2Ndof &&
                        ((ptShift > ps.maxPt && track.ipChi2 > ps.minIPChi2) ||
                         (ptShift > ps.minPt && ptShift < ps.maxPt &&
                          logf(track.ipChi2) > ps.param1 / (ptShift - ps.param2) / (ptShift - ps.param2) +
                                                 ps.param3 / ps.maxPt * (ps.maxPt - ptShift) + logf(ps.minIPChi2)));
  return decision;
}
