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
#include "DownstreamLambda2PPiLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(downstream_lambdatoppi_line::downstream_lambdatoppi_line_t, downstream_lambdatoppi_line::Parameters)

__device__ bool downstream_lambdatoppi_line::downstream_lambdatoppi_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto composite = std::get<0>(input);
  const auto idx = std::get<1>(input);
  const auto& l0_mva = parameters.dev_downstream_mva_l0[idx];
  const auto& detached_l0_mva = parameters.dev_downstream_mva_detached_l0[idx];

  const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(0));
  const auto c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(1));

  const auto composite_mass =
    c0->state().p() > c1->state().p() ? composite.m12(Allen::mP, Allen::mPi) : composite.m12(Allen::mPi, Allen::mP);

  return (l0_mva > properties.mva_l0_threshold) && (detached_l0_mva > properties.mva_detached_l0_threshold) &&
         (composite_mass > properties.minMass) && (composite_mass < properties.maxMass);
}

__device__ void downstream_lambdatoppi_line::downstream_lambdatoppi_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto l0 = std::get<0>(input);

    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(l0.child(0));
    const auto c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(l0.child(1));

    const auto l0_mass =
      c0->state().p() > c1->state().p() ? l0.m12(Allen::mP, Allen::mPi) : l0.m12(Allen::mPi, Allen::mP);
    const float pt = l0.vertex().pt();

    properties.histogram_l0_mass.increment(l0_mass);
    properties.histogram_l0_pt.increment(pt);
  }
}

__device__ bool downstream_lambdatoppi_line::downstream_lambdatoppi_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto l0 = std::get<0>(input);
    const auto idx = std::get<1>(input);
    const auto& l0_mva = parameters.dev_downstream_mva_l0[idx];
    const auto& detached_l0_mva = parameters.dev_downstream_mva_detached_l0[idx];

    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(l0.child(0));
    const auto c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(l0.child(1));

    const auto l0_mass =
      c0->state().p() > c1->state().p() ? l0.m12(Allen::mP, Allen::mPi) : l0.m12(Allen::mPi, Allen::mP);
    parameters.l0_mass[index] = l0_mass;
    parameters.l0_pt[index] = l0.vertex().pt();
    parameters.mva_l0_detached[index] = detached_l0_mva;
    parameters.mva_l0_prompt[index] = l0_mva;
  }
  return sel;
}
