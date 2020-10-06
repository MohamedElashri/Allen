#include "SingleHighPtMuonLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(single_high_pt_muon_line::single_high_pt_muon_line_t, single_high_pt_muon_line::Parameters)

__device__ bool single_high_pt_muon_line::single_high_pt_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input) const
{
  const auto& track = std::get<0>(input);
  const bool decision = track.chi2 / track.ndof < parameters.maxChi2Ndof && track.pt() > parameters.singleMinPt &&
                        track.p() > parameters.singleMinP && track.is_muon;
  return decision;
}
