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

void SMOG2_kstopipi_line::SMOG2_kstopipi_line_t::init()
{
  Line<SMOG2_kstopipi_line::SMOG2_kstopipi_line_t, SMOG2_kstopipi_line::Parameters>::init();

  m_histogram_smogks_mass.axis().nBins = property<histogram_smogks_mass_nbins_t>();
  m_histogram_smogks_mass.axis().minValue = property<histogram_smogks_mass_min_t>();
  m_histogram_smogks_mass.axis().maxValue = property<histogram_smogks_mass_max_t>();

  m_histogram_smogks_svz.axis().nBins = property<histogram_smogks_svz_nbins_t>();
  m_histogram_smogks_svz.axis().minValue = property<histogram_smogks_svz_min_t>();
  m_histogram_smogks_svz.axis().maxValue = property<histogram_smogks_svz_max_t>();
}

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
  const Parameters& parameters,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto smogks = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(smogks.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(smogks.child(1));

  if (sel) {
    parameters.sv_masses[index] = smogks.m12(Allen::mPi, Allen::mPi);
    parameters.svz[index] = smogks.vertex().z();
    parameters.track1pt[index] = track1->state().pt();
    parameters.track2pt[index] = track2->state().pt();
    parameters.minipchi2[index] = smogks.minipchi2();
    parameters.ip[index] = smogks.ip();

    accumulators.histogram_smogks_mass.increment(smogks.m12(Allen::mPi, Allen::mPi));
    accumulators.histogram_smogks_svz.increment(smogks.vertex().z());
  }
}

__device__ void SMOG2_kstopipi_line::SMOG2_kstopipi_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto particle = std::get<0>(input);
  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  if (sel) {
    parameters.sv_masses[index] = particle.m12(Allen::mPi, Allen::mPi);
    parameters.minipchi2[index] = particle.minipchi2();
    parameters.ip[index] = particle.ip();
    parameters.svz[index] = particle.vertex().z();
    parameters.track1pt[index] = trk1->state().pt();
    parameters.track2pt[index] = trk2->state().pt();
  }
}
