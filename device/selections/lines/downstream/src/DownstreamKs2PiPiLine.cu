/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DownstreamKs2PiPiLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(downstream_kstopipi_line::downstream_kstopipi_line_t, downstream_kstopipi_line::Parameters)

__device__ bool downstream_kstopipi_line::downstream_kstopipi_line_t::select(
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto composite = std::get<0>(input);
  const auto idx = std::get<1>(input);
  const auto& ks_mva = parameters.dev_downstream_mva_ks[idx];
  const auto& detached_ks_mva = parameters.dev_downstream_mva_detached_ks[idx];

  const auto composite_mass = composite.m12(Allen::mPi, Allen::mPi);

  // printf("mva=%f, mass=%f\n", ks_mva, composite_mass);

  return (ks_mva > parameters.mva_ks_threshold.get()) &&
         (detached_ks_mva > parameters.mva_detached_ks_threshold.get()) &&
         (composite_mass > parameters.minMass.get()) && (composite_mass < parameters.maxMass.get());
}

__device__ void downstream_kstopipi_line::downstream_kstopipi_line_t::monitor(
  const Parameters& parameters,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto ks = std::get<0>(input);
    parameters.ks_mass[index] = ks.m12(Allen::mPi, Allen::mPi);
    parameters.ks_pt[index] = ks.vertex().pt();

    accumulators.histogram_ks_mass.increment(ks.m12(Allen::mPi, Allen::mPi));
    accumulators.histogram_ks_pt.increment(ks.vertex().pt());
  }
}