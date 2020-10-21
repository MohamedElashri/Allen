/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "D2KPiLine.cuh"

INSTANTIATE_LINE(d2kpi_line::d2kpi_line_t, d2kpi_line::Parameters)

__device__ bool d2kpi_line::d2kpi_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input) const
{
  const auto& vertex = std::get<0>(input);
  if (vertex.chi2 < 0) {
    return false;
  }
  const float m1 = vertex.m(parameters.mK, parameters.mPi);
  const float m2 = vertex.m(parameters.mPi, parameters.mK);
  const bool decision =
    vertex.pt() > parameters.minComboPt && vertex.chi2 < parameters.maxVertexChi2 && vertex.eta > parameters.minEta &&
    vertex.eta < parameters.maxEta && vertex.minpt > parameters.minTrackPt &&
    vertex.minipchi2 > parameters.minTrackIPChi2 &&
    min(fabsf(m1 - parameters.mD), fabsf(m2 - parameters.mD)) < parameters.massWindow;
  return decision;
}
