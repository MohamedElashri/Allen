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
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto composite = std::get<0>(input);
  const auto idx = std::get<1>(input);
  const auto& ks_mva = parameters.dev_downstream_mva_ks[idx];
  const auto& detached_ks_mva = parameters.dev_downstream_mva_detached_ks[idx];

  const auto composite_mass = composite.m12(Allen::mPi, Allen::mPi);

  // printf("mva=%f, mass=%f\n", ks_mva, composite_mass);

  return (ks_mva > properties.mva_ks_threshold) && (detached_ks_mva > properties.mva_detached_ks_threshold) &&
         (composite_mass > properties.minMass) && (composite_mass < properties.maxMass);
}

__device__ void downstream_kstopipi_line::downstream_kstopipi_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto ks = std::get<0>(input);
    properties.histogram_ks_mass.increment(ks.m12(Allen::mPi, Allen::mPi));
    properties.histogram_ks_pt.increment(ks.vertex().pt());
  }
}

__device__ bool downstream_kstopipi_line::downstream_kstopipi_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto ks = std::get<0>(input);
    const auto idx = std::get<1>(input);
    const auto& ks_mva = parameters.dev_downstream_mva_ks[idx];
    const auto& detached_ks_mva = parameters.dev_downstream_mva_detached_ks[idx];
    parameters.ks_mass[index] = ks.m12(Allen::mPi, Allen::mPi);
    parameters.ks_pt[index] = ks.vertex().pt();
    parameters.mva_ks_detached[index] = detached_ks_mva;
    parameters.mva_ks_prompt[index] = ks_mva;
  }
  return sel;
}
