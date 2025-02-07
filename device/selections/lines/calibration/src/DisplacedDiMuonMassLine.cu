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
#include "DisplacedDiMuonMassLine.cuh"

INSTANTIATE_LINE(displaced_di_muon_mass_line::displaced_di_muon_mass_line_t, displaced_di_muon_mass_line::Parameters)

__device__ bool displaced_di_muon_mass_line::displaced_di_muon_mass_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.charge() != properties.diMuonCharge) return false;
  if (vertex.minipchi2() < properties.dispMinIPChi2) return false;
  if (vertex.mdimu() < properties.minMass) return false;

  bool decision = vertex.vertex().chi2() > 0 && vertex.vertex().chi2() < properties.maxVertexChi2 &&
                  vertex.eta() > properties.dispMinEta && vertex.eta() < properties.dispMaxEta &&
                  vertex.minpt() > properties.minDispTrackPt && vertex.vertex().z() >= properties.minZ;
  return decision;
}
