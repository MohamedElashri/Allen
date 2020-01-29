#include "SingleMuonLine.cuh"

__device__ bool SingleMuon::SingleMuon_t::function(const ParKalmanFilter::FittedTrack& track)
{
  bool decision = track.chi2 / track.ndof < maxChi2Ndof;
  decision &= track.pt() > singleMinPt;
  decision &= track.is_muon;
  return decision;
}
