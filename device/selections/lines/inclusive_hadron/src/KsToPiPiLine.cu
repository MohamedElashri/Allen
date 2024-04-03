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
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const bool opposite_sign = vertex.charge() == 0;
  const bool double_muon_misid =
    (vertex.is_dimuon() && track1->state().p() >= 10000.f && track2->state().p() >= 10000.f);
  if (parameters.double_muon_misid && !double_muon_misid) return false;

  const bool decision = vertex.has_pv() && vertex.minipchi2() > parameters.minIPChi2 &&
                        opposite_sign == parameters.OppositeSign && vertex.vertex().chi2() < parameters.maxVertexChi2 &&
                        vertex.ip() < parameters.maxIP && vertex.m12(Allen::mPi, Allen::mPi) > parameters.minMass &&
                        vertex.m12(Allen::mPi, Allen::mPi) < parameters.maxMass &&
                        vertex.pv().position.z >= parameters.minZ && vertex.vertex().z() >= parameters.minZ;

  return decision;
}

__device__ void kstopipi_line::kstopipi_line_t::monitor(
  const Parameters& parameters,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto ks = std::get<0>(input);
  if (sel) {
    parameters.sv_masses[index] = ks.m12(Allen::mPi, Allen::mPi);
    parameters.pt[index] = ks.vertex().pt();
    parameters.mipchi2[index] = ks.minipchi2();

    accumulators.histogram_ks_mass.increment(ks.m12(Allen::mPi, Allen::mPi));
    accumulators.histogram_ks_pt.increment(ks.vertex().pt());
  }
}
