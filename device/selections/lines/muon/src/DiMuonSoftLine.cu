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
#include "DiMuonSoftLine.cuh"

INSTANTIATE_LINE(di_muon_soft_line::di_muon_soft_line_t, di_muon_soft_line::Parameters)

__device__ bool di_muon_soft_line::di_muon_soft_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const bool opposite_sign = vertex.charge() == 0;

  if (!vertex.is_dimuon()) return false;
  if (vertex.minipchi2() < properties.DMSoftMinIPChi2) return false;
  if (opposite_sign != properties.oppositeSign) return false;

  // KS pipi misid veto
  const bool decision =
    vertex.vertex().chi2() > 0 && (vertex.mdimu() < properties.DMSoftM0 || vertex.mdimu() > properties.DMSoftM1) &&
    (vertex.mdimu() < properties.DMSoftM2) && vertex.eta() > 0 &&
    (vertex.vertex().x() * vertex.vertex().x() + vertex.vertex().y() * vertex.vertex().y()) >
      properties.DMSoftMinRho2 &&
    (vertex.vertex().z() > properties.DMSoftMinZ) && (vertex.vertex().z() < properties.DMSoftMaxZ) &&
    vertex.doca12() < properties.DMSoftMaxDOCA && vertex.ip() / vertex.dz() < properties.DMSoftMaxIPDZ &&
    vertex.clone_sin2() > properties.DMSoftGhost;
  return decision;
}
