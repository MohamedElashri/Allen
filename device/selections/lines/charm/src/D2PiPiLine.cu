/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "D2PiPiLine.cuh"

INSTANTIATE_LINE(d2pipi_line::d2pipi_line_t, d2pipi_line::Parameters)

__device__ bool d2pipi_line::d2pipi_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const bool opposite_sign = particle.charge() == 0;
  if (opposite_sign != parameters.OppositeSign) return false;
  const auto vertex = particle.vertex();
  if (vertex.chi2() < 0) {
    return false;
  }
  const bool decision = vertex.pt() > parameters.minComboPt && vertex.chi2() < parameters.maxVertexChi2 &&
                        particle.eta() > parameters.minEta && particle.eta() < parameters.maxEta &&
                        particle.doca12() < parameters.maxDOCA && particle.minpt() > parameters.minTrackPt &&
                        particle.minip() > parameters.minTrackIP &&
                        particle.ctau(Allen::mDz) > parameters.ctIPScale * parameters.minTrackIP &&
                        fabsf(particle.m12(Allen::mPi, Allen::mPi) - Allen::mDz) < parameters.massWindow &&
                        vertex.z() >= parameters.minZ && particle.pv().position.z >= parameters.minZ;

  return decision;
}

__device__ void d2pipi_line::d2pipi_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& particle = std::get<0>(input);
    // Use the following variables in bandwidth division
    parameters.min_pt[index] = particle.minpt(); // This should range in [800., 2000.]
    parameters.min_ip[index] = particle.minip(); // This should range in [0.06, 0.15]
    parameters.D0_ct[index] = particle.ctau(Allen::mDz);
  }
}
