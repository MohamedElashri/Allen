/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "D2KPiLine.cuh"

INSTANTIATE_LINE(d2kpi_line::d2kpi_line_t, d2kpi_line::Parameters)

__device__ bool d2kpi_line::d2kpi_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  if (vertex.vertex().chi2() < 0) {
    return false;
  }
  const float m1 = vertex.m12(Allen::mK, Allen::mPi);
  const float m2 = vertex.m12(Allen::mPi, Allen::mK);
  const bool decision = vertex.pt() > parameters.minComboPt && vertex.vertex().chi2() < parameters.maxVertexChi2 &&
                        vertex.eta() > parameters.minEta && vertex.eta() < parameters.maxEta &&
                        vertex.minpt() > parameters.minTrackPt && vertex.minip() > parameters.minTrackIP &&
                        min(fabsf(m1 - Allen::mDz), fabsf(m2 - Allen::mDz)) < parameters.massWindow;
  return decision;
}
