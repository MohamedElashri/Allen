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
#include "LowPtDiMuonLine.cuh"

INSTANTIATE_LINE(low_pt_di_muon_line::low_pt_di_muon_line_t, low_pt_di_muon_line::Parameters)

__device__ bool low_pt_di_muon_line::low_pt_di_muon_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.minipchi2() < properties.minTrackIPChi2) return false;
  if (vertex.minip() < properties.minTrackIP) return false;
  const bool opposite_sign = vertex.charge() == 0;
  if (opposite_sign != properties.oppositeSign) return false;

  const bool decision = vertex.vertex().chi2() > 0 && vertex.mdimu() > properties.minMass &&
                        vertex.minpt() > properties.minTrackPt && vertex.minp() > properties.minTrackP &&
                        vertex.vertex().chi2() < properties.maxVertexChi2 && vertex.doca12() < properties.maxDOCA &&
                        vertex.vertex().z() >= properties.minZ && vertex.pv().position.z >= properties.minZ;
  return decision;
}
