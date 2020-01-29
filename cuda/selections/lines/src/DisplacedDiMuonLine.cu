#include "DisplacedDiMuonLine.cuh"

__host__ __device__ bool DisplacedDiMuon::DisplacedDiMuon(const VertexFit::TrackMVAVertex& vertex)
{
  if (!vertex.is_dimuon) return false;
  if (vertex.minipchi2 < dispMinIPChi2) return false;

  bool decision = vertex.chi2 > 0;
  decision &= vertex.chi2 < maxVertexChi2;
  decision &= vertex.eta > dispMinEta && vertex.eta < dispMaxEta;
  decision &= vertex.minpt > minDispTrackPt;
  return decision;
}
