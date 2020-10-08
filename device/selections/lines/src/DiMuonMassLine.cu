#include "DiMuonMassLine.cuh"

INSTANTIATE_LINE(di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters)

__device__ bool di_muon_mass_line::di_muon_mass_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input) const
{
  const auto& vertex = std::get<0>(input);
  return vertex.is_dimuon && vertex.minipchi2 >= parameters.minIPChi2 && vertex.doca <= parameters.maxDoca &&
         vertex.mdimu >= parameters.minMass && vertex.minpt >= parameters.minHighMassTrackPt &&
         vertex.p1 >= parameters.minHighMassTrackP && vertex.p2 >= parameters.minHighMassTrackP && vertex.chi2 > 0 &&
         vertex.chi2 < parameters.maxVertexChi2;
}
