/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "LowPtDiMuonLine.cuh"

INSTANTIATE_LINE(low_pt_di_muon_line::low_pt_di_muon_line_t, low_pt_di_muon_line::Parameters)

__device__ bool low_pt_di_muon_line::low_pt_di_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vertex = std::get<0>(input);

  if (!vertex.is_dimuon) return false;
  if (vertex.minipchi2 < parameters.minTrackIPChi2) return false;
  if (vertex.minip < parameters.minTrackIP) return false;

  const bool decision = vertex.chi2 > 0 && vertex.mdimu > parameters.minMass && vertex.minpt > parameters.minTrackPt &&
                        vertex.p1 > parameters.minTrackP && vertex.p2 > parameters.minTrackP &&
                        vertex.chi2 < parameters.maxVertexChi2 && vertex.doca < parameters.maxDOCA;
  return decision;
}
