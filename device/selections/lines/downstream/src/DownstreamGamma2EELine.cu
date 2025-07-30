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
#include "DownstreamGamma2EELine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(downstream_gammatoee_line::downstream_gammatoee_line_t, downstream_gammatoee_line::Parameters)

__device__ bool downstream_gammatoee_line::downstream_gammatoee_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto composite = std::get<0>(input);
  const auto dA = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(0));
  const auto dB = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(1));

  if (composite.vertex().chi2() < 0) {
    return false;
  }

  bool dA_is_electron = dA->is_electron();
  bool dB_is_electron = dB->is_electron();

  // quantities
  const auto composite_mass = composite.m12(Allen::mEl, Allen::mEl);
  const auto armenteros_y = composite.vertex().downstream_armentero_podolanski_y();

  return (dA_is_electron && dB_is_electron) && (composite.vertex().pt() > properties.minPt) &&
         (composite_mass > properties.minMass) && (composite_mass < properties.maxMass) &&
         (armenteros_y < properties.maxArmenterosY);
}

__device__ void downstream_gammatoee_line::downstream_gammatoee_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto gamma = std::get<0>(input);
    properties.histogram_gamma_mass.increment(gamma.m12(Allen::mEl, Allen::mEl));
    properties.histogram_gamma_pt.increment(gamma.vertex().pt());
  }
}

__device__ bool downstream_gammatoee_line::downstream_gammatoee_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto gamma = std::get<0>(input);
    parameters.gamma_mass[index] = gamma.m12(Allen::mEl, Allen::mEl);
    // Use the following variable in bandwidth division
    parameters.gamma_pt[index] = gamma.vertex().pt();
  }
  return sel;
}