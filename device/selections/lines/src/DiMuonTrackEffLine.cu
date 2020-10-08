#include "DiMuonTrackEffLine.cuh"

INSTANTIATE_LINE(di_muon_track_eff_line::di_muon_track_eff_line_t, di_muon_track_eff_line::Parameters)

__device__ bool di_muon_track_eff_line::di_muon_track_eff_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input) const
{
  const auto& vertex = std::get<0>(input);
  if (!vertex.is_dimuon) return false;
  const bool decision = vertex.chi2 > 0 && vertex.mdimu > parameters.DMTrackEffM0 && vertex.mdimu < parameters.DMTrackEffM1;
  return decision;
}
