/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "D2KKLine.cuh"

INSTANTIATE_LINE(d2kk_line::d2kk_line_t, d2kk_line::Parameters)

__device__ bool d2kk_line::d2kk_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const auto vertex = particle.vertex();
  if (vertex.chi2() < 0) {
    return false;
  }
  const bool decision = vertex.pt() > parameters.minComboPt && vertex.chi2() < parameters.maxVertexChi2 &&
                        particle.eta() > parameters.minEta && particle.eta() < parameters.maxEta &&
                        particle.minpt() > parameters.minTrackPt &&
                        fabsf(particle.m12(Allen::mK, Allen::mK) - Allen::mDz) < parameters.massWindow;
  return decision;
}
