/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "D2KPiLine.cuh"

INSTANTIATE_LINE(d2kpi_line::d2kpi_line_t, d2kpi_line::Parameters)

__device__ bool d2kpi_line::d2kpi_line_t::select(
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const bool opposite_sign = particle.charge() == 0;
  if (opposite_sign != parameters.OppositeSign) return false;

  const auto vertex = particle.vertex();
  if (vertex.chi2() < 0) {
    return false;
  }
  const float m1 = particle.m12(Allen::mK, Allen::mPi);
  const float m2 = particle.m12(Allen::mPi, Allen::mK);
  const bool decision = vertex.pt() > parameters.minComboPt && vertex.chi2() < parameters.maxVertexChi2 &&
                        particle.dira() > parameters.minDira && particle.eta() > parameters.minEta &&
                        particle.eta() < parameters.maxEta && particle.doca12() < parameters.maxDOCA &&
                        particle.minpt() > parameters.minTrackPt && particle.minp() > parameters.minTrackP &&
                        particle.has_pv() && particle.minip() > parameters.minTrackIP &&
                        particle.ctau(Allen::mDz) > parameters.ctIPScale * parameters.minTrackIP &&
                        min(fabsf(m1 - Allen::mDz), fabsf(m2 - Allen::mDz)) < parameters.massWindow &&
                        vertex.z() >= parameters.minZ && particle.pv().position.z >= parameters.minZ;

  return decision;
}

__device__ void d2kpi_line::d2kpi_line_t::monitor(
  const Parameters&,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  const auto particle = std::get<0>(input);
  const auto vertex = particle.vertex();
  if (sel) {
    accumulators.histogram_d0_mass.increment(particle.m12(Allen::mK, Allen::mPi));
    accumulators.histogram_d0_mass.increment(particle.m12(Allen::mPi, Allen::mK));
    accumulators.histogram_d0_pt.increment(vertex.pt());
  }
}

__device__ void d2kpi_line::d2kpi_line_t::fill_tuples(
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
