#include "DiMuonSoftLine.cuh"

INSTANTIATE_LINE(di_muon_soft_line::di_muon_soft_line_t, di_muon_soft_line::Parameters)

__device__ bool di_muon_soft_line::di_muon_soft_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input) const
{
  const auto& vertex = std::get<0>(input);

  if (!vertex.is_dimuon) return false;
  if (vertex.minipchi2 < DMSoftMinIPChi2) return false;

  // KS pipi misid veto
  const bool decision =
    vertex.chi2 > 0 && (vertex.mdimu < parameters.DMSoftM0 || vertex.mdimu > parameters.DMSoftM1) &&
    (vertex.mdimu < parameters.DMSoftM2) && vertex.eta > 0 &&
    (vertex.x * vertex.x + vertex.y * vertex.y) > parameters.DMSoftMinRho2 &&
    (vertex.z > parameters.DMSoftMinZ) && (vertex.z < parameters.DMSoftMaxZ) && vertex.doca < parameters.DMSoftMaxDOCA &&
    vertex.vertex_ip / vertex.dz < parameters.DMSoftMaxIPDZ && vertex.vertex_clone_sin2 > parameters.DMSoftGhost;
  return decision;
}
