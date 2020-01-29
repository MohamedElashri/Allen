#include "HighMassDiMuonLine.cuh"

__device__ bool HighMassDiMuon::HighMassDiMuon_t::function(const VertexFit::TrackMVAVertex& vertex)
{
  if (!vertex.is_dimuon) return false;
  if (vertex.mdimu < minMass) return false;
  if (vertex.minpt < minHighMassTrackPt) return false;

  bool decision = vertex.chi2 > 0;
  decision &= vertex.chi2 < maxVertexChi2;
  return decision;
}
