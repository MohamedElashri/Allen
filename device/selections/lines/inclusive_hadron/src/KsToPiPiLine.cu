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
#include "KsToPiPiLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters)

__device__ bool kstopipi_line::kstopipi_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const bool opposite_sign = vertex.charge() == 0;
  const bool double_muon_misid =
    (vertex.is_dimuon() && track1->state().p() >= 10000.f && track2->state().p() >= 10000.f);
  if (properties.double_muon_misid && !double_muon_misid) return false;

  const bool decision = vertex.has_pv() && vertex.minipchi2() > properties.minIPChi2 &&
                        opposite_sign == properties.oppositeSign && vertex.vertex().chi2() < properties.maxVertexChi2 &&
                        vertex.ip() < properties.maxIP && vertex.m12(Allen::mPi, Allen::mPi) > properties.minMass &&
                        vertex.m12(Allen::mPi, Allen::mPi) < properties.maxMass &&
                        vertex.pv().position.z >= properties.minZ && vertex.vertex().z() >= properties.minZ;
  return decision;
}

__device__ void kstopipi_line::kstopipi_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto ks = std::get<0>(input);
    properties.histogram_ks_mass.increment(ks.m12(Allen::mPi, Allen::mPi));
    properties.histogram_ks_pt.increment(ks.vertex().pt());
    const auto p0 = static_cast<const Allen::Views::Physics::BasicParticle*>(std::get<0>(input).child(0));
    const auto p1 = static_cast<const Allen::Views::Physics::BasicParticle*>(std::get<0>(input).child(1));
    properties.histogram_p0_ghost_prob.increment(p0->track().ghost_probability());
    properties.histogram_p1_ghost_prob.increment(p1->track().ghost_probability());
  }
}

__device__ bool kstopipi_line::kstopipi_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto ks = std::get<0>(input);
    parameters.sv_masses[index] = ks.m12(Allen::mPi, Allen::mPi);
    parameters.pt[index] = ks.vertex().pt();
    parameters.mipchi2[index] = ks.minipchi2();
  }
  return sel;
}
