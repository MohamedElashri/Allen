/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "D2KPiLine.cuh"

INSTANTIATE_LINE(d2kpi_line::d2kpi_line_t, d2kpi_line::Parameters)

__device__ bool d2kpi_line::d2kpi_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const auto vertex = particle.vertex();
  if (vertex.chi2() < 0) {
    return false;
  }
  const float m1 = particle.m12(Allen::mK, Allen::mPi);
  const float m2 = particle.m12(Allen::mPi, Allen::mK);
  const bool decision = vertex.pt() > parameters.minComboPt && vertex.chi2() < parameters.maxVertexChi2 &&
                        particle.eta() > parameters.minEta && particle.eta() < parameters.maxEta &&
                        particle.minpt() > parameters.minTrackPt &&
                        min(fabsf(m1 - Allen::mDz), fabsf(m2 - Allen::mDz)) < parameters.massWindow;
  return decision;
}
