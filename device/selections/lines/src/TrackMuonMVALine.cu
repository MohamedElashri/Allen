#include "TrackMuonMVALine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(track_muon_mva_line::track_muon_mva_line_t, track_muon_mva_line::Parameters)

__device__ bool track_muon_mva_line::track_muon_mva_line_t::select(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input) const
{
  const auto& track = std::get<0>(input);
  if (!track.is_muon) {
    return false;
  }

  float ptShift = (track.pt() - parameters.alpha) / Gaudi::Units::GeV;
  const bool decision =
    track.chi2 / track.ndof < parameters.maxChi2Ndof &&
    ((ptShift > parameters.maxPt && track.ipChi2 > parameters.minIPChi2) ||
     (ptShift > parameters.minPt && ptShift < parameters.maxPt &&
      logf(track.ipChi2) > parameters.param1 / ((ptShift - parameters.param2) * (ptShift - parameters.param2)) +
                             parameters.param3 / parameters.maxPt * (parameters.maxPt - ptShift) +
                             logf(parameters.minIPChi2)));
  return decision;
}
