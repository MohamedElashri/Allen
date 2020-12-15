/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "TwoTrackMVALine.cuh"

INSTANTIATE_LINE(two_track_mva_line::two_track_mva_line_t, two_track_mva_line::Parameters)

__device__ bool two_track_mva_line::two_track_mva_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vertex = std::get<0>(input);
  if (vertex.chi2 < 0) {
    return false;
  }
  const bool decision = vertex.pt() > parameters.minComboPt && vertex.chi2 < parameters.maxVertexChi2 &&
                        vertex.mcor > parameters.minMCor &&
                        (vertex.eta > parameters.minEta && vertex.eta < parameters.maxEta) &&
                        vertex.ntrks16 <= parameters.maxNTrksAssoc && vertex.fdchi2 > parameters.minFDChi2 &&
                        vertex.minipchi2 > parameters.minTrackIPChi2 && vertex.minpt > parameters.minTrackPt;
  return decision;
}
