#include "DiMuonSoftLine.cuh"

__device__ bool DiMuonSoft::DiMuonSoft_t::function(const VertexFit::TrackMVAVertex& vertex)
{
  if (!vertex.is_dimuon) return false;
  if (vertex.minipchi2 < DMSoftMinIPChi2) return false;
  bool decision = vertex.chi2 > 0;
  decision &= (vertex.mdimu < DMSoftM0 || vertex.mdimu > DMSoftM1); // KS pipi misid veto
  decision &= vertex.eta > 0;

  decision &= (vertex.x * vertex.x + vertex.y * vertex.y) > DMSoftMinRho2;
  decision &= (vertex.z > DMSoftMinZ) & (vertex.z < DMSoftMaxZ);
  decision &= vertex.doca < DMSoftMaxDOCA;
  decision &= vertex.dimu_ip / vertex.dz < DMSoftMaxIPDZ;
  decision &= vertex.dimu_clone_sin2 > DMSoftGhost;
  return decision;
}
