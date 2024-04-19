/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "SMOG2_KsToPiPi.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(SMOG2_kstopipi_line::SMOG2_kstopipi_line_t, SMOG2_kstopipi_line::Parameters)

__device__ bool SMOG2_kstopipi_line::SMOG2_kstopipi_line_t::select(
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  return vertex.has_pv() && vertex.pv().position.z >= parameters.minPVZ && vertex.pv().position.z < parameters.maxPVZ &&
         vertex.minipchi2() > parameters.minIPChi2 && vertex.charge() == parameters.CombCharge &&
         track1->state().pt() > parameters.minTrackPt && track2->state().pt() > parameters.minTrackPt &&
         vertex.vertex().chi2() < parameters.maxVertexChi2 && vertex.ip() < parameters.maxIP &&
         vertex.m12(Allen::mPi, Allen::mPi) >= parameters.minMass &&
         vertex.m12(Allen::mPi, Allen::mPi) < parameters.maxMass && vertex.vertex().z() >= parameters.minPVZ;
}

__device__ void SMOG2_kstopipi_line::SMOG2_kstopipi_line_t::monitor(
  const Parameters&,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto smogks = std::get<0>(input);

    accumulators.histogram_smogks_mass.increment(smogks.m12(Allen::mPi, Allen::mPi));
    accumulators.histogram_smogks_svz.increment(smogks.vertex().z());
    accumulators.histogram_smogks_pt.increment(smogks.vertex().pt());
    accumulators.histogram_smogks_pvz.increment(smogks.pv().position.z);
  }
}

__device__ void SMOG2_kstopipi_line::SMOG2_kstopipi_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
    const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

    parameters.sv_masses[index] = particle.m12(Allen::mPi, Allen::mPi);
    parameters.minipchi2[index] = particle.minipchi2();
    parameters.ip[index] = particle.ip();
    parameters.svz[index] = particle.vertex().z();
    parameters.track1pt[index] = trk1->state().pt();
    parameters.track2pt[index] = trk2->state().pt();
    parameters.minipchi2[index] = particle.minipchi2();
    parameters.pvz[index] = particle.pv().position.z;
    parameters.pt[index] = particle.vertex().pt();
  }
}
