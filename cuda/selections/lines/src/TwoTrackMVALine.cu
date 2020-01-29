#include "TwoTrackMVALine.cuh"

__device__ bool TwoTrackMVA::TwoTrackMVA_t::function(const VertexFit::TrackMVAVertex& vertex)
{
  if (vertex.chi2 < 0) {
    return false;
  }
  bool decision = vertex.pt() > minComboPt;
  decision &= vertex.chi2 < maxVertexChi2;
  decision &= vertex.mcor > minMCor;
  decision &= vertex.eta > minEta && vertex.eta < maxEta;
  decision &= vertex.ntrksassoc <= maxNTrksAssoc;
  decision &= vertex.fdchi2 > minFDChi2;
  decision &= vertex.minipchi2 > minTrackIPChi2;
  decision &= vertex.minpt > minTrackPt;
  return decision;
}
