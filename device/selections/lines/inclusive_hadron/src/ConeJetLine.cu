/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ConeJetLine.cuh"

INSTANTIATE_LINE(cone_jet_line::cone_jet_line_t, cone_jet_line::Parameters)

__device__ bool cone_jet_line::cone_jet_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::NeutralBasicParticle> input)
{
  const auto& jet = std::get<0>(input);
  bool decision = jet.et() > properties.min_jet_pt && jet.et() < properties.max_jet_pt;
  return decision;
}

__device__ bool cone_jet_line::cone_jet_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::NeutralBasicParticle> input,
  unsigned index,
  bool)
{
  const auto jet = std::get<0>(input);
  parameters.jet_pt[index] = jet.et();
  parameters.jet_eta[index] = jet.eta();
  parameters.jet_phi[index] = jet.phi();
  return true;
}