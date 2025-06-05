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
#include "DiProtonHighMassLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(diproton_highmass_line::diproton_highmass_line_t, diproton_highmass_line::Parameters)

__device__ bool diproton_highmass_line::diproton_highmass_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const bool opposite_sign = vertex.charge() == 0;
  const float ptAsym = std::fabs((track1->state().pt() - track2->state().pt()) / vertex.vertex().pt());
  const float ppMass = vertex.m12(Allen::mP, Allen::mP);

  const bool decision =
    vertex.has_pv() && track1->has_pv() && track2->has_pv() && track1->state().p() > properties.minP_p &&
    track2->state().p() > properties.minP_p && track1->state().pt() > properties.minPT_p &&
    track2->state().pt() > properties.minPT_p && track1->track().ghost_probability() < properties.maxGhostProb &&
    track2->track().ghost_probability() < properties.maxGhostProb && opposite_sign == properties.oppositeSign &&
    vertex.vertex().chi2() < properties.maxVertexChi2 && ppMass > properties.minMass && ppMass < properties.maxMass &&
    vertex.vertex().pt() > properties.minPT_pp && vertex.vertex().p() > properties.minP_pp &&
    ptAsym < properties.maxPtAsym;
  return decision;
}

__device__ void diproton_highmass_line::diproton_highmass_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto pp = std::get<0>(input);
    properties.histogram_pp_mass.increment(pp.m12(Allen::mP, Allen::mP));
    properties.histogram_pp_pt.increment(pp.vertex().pt());
    const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(pp.child(0));
    const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(pp.child(1));
    properties.histogram_track1_ghost_prob.increment(track1->track().ghost_probability());
    properties.histogram_track2_ghost_prob.increment(track2->track().ghost_probability());
    properties.histogram_p_pt.increment(track1->state().pt());
    properties.histogram_p_p.increment(track1->state().p());
  }
}

__device__ bool diproton_highmass_line::diproton_highmass_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto pp = std::get<0>(input);
    parameters.pp_mass[index] = pp.m12(Allen::mP, Allen::mP);
    parameters.pp_pt[index] = pp.vertex().pt();
    parameters.pp_p[index] = pp.vertex().p();
    const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(pp.child(0));
    const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(pp.child(1));
    parameters.p_pt[index] = track1->state().pt();
    parameters.p_p[index] = track1->state().p();
    parameters.ptasym[index] = std::fabs((track1->state().pt() - track2->state().pt()) / pp.vertex().pt());
  }
  return sel;
}
