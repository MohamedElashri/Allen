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
#include "D2KKLine.cuh"

INSTANTIATE_LINE(d2kk_line::d2kk_line_t, d2kk_line::Parameters)

__device__ bool d2kk_line::d2kk_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const bool opposite_sign = particle.charge() == 0;
  if (opposite_sign != properties.OppositeSign) return false;
  const auto vertex = particle.vertex();
  if (vertex.chi2() < 0) {
    return false;
  }
  const bool decision = vertex.pt() > properties.minComboPt && vertex.chi2() < properties.maxVertexChi2 &&
                        particle.eta() > properties.minEta && particle.eta() < properties.maxEta &&
                        particle.doca12() < properties.maxDOCA && particle.minpt() > properties.minTrackPt &&
                        particle.has_pv() && particle.minip() > properties.minTrackIP &&
                        particle.ctau(Allen::mDz) > properties.ctIPScale * properties.minTrackIP &&
                        fabsf(particle.m12(Allen::mK, Allen::mK) - Allen::mDz) < properties.massWindow &&
                        vertex.z() >= properties.minZ && particle.pv().position.z >= properties.minZ;

  return decision;
}

__device__ void d2kk_line::d2kk_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  const auto particle = std::get<0>(input);
  const auto vertex = particle.vertex();
  if (sel) {
    properties.histogram_d02kk_mass.increment(particle.m12(Allen::mK, Allen::mK));
    properties.histogram_d02kk_pt.increment(vertex.pt());
  }
}

__device__ bool d2kk_line::d2kk_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
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
  return sel;
}
