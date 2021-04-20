/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DisplacedDiMuonLine.cuh"

INSTANTIATE_LINE(displaced_di_muon_line::displaced_di_muon_line_t, displaced_di_muon_line::Parameters)

__device__ bool displaced_di_muon_line::displaced_di_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vertex = std::get<0>(input);

  if (!vertex.is_dimuon) return false;
  if (vertex.minipchi2 < parameters.dispMinIPChi2) return false;
  // TODO temporary hardcoded mass cut to reduce CPU-GPU differences
  if (vertex.mdimu < 215.f) return false;

  bool decision = vertex.chi2 > 0 && vertex.chi2 < parameters.maxVertexChi2 && vertex.eta > parameters.dispMinEta &&
                  vertex.eta < parameters.dispMaxEta && vertex.minpt > parameters.minDispTrackPt;
  return decision;
}
