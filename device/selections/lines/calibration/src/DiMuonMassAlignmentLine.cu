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
#include "DiMuonMassAlignmentLine.cuh"

INSTANTIATE_LINE(di_muon_mass_alignment_line::di_muon_mass_alignment_line_t, di_muon_mass_alignment_line::Parameters)

__device__ bool di_muon_mass_alignment_line::di_muon_mass_alignment_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  if (vertex.charge() != parameters.DiMuonCharge) return false;

  return vertex.is_dimuon() && vertex.minipchi2() >= parameters.minIPChi2 && vertex.doca12() <= parameters.maxDoca &&
         vertex.mdimu() >= parameters.minMass && vertex.minpt() >= parameters.minHighMassTrackPt &&
         vertex.minp() >= parameters.minHighMassTrackP && vertex.vertex().chi2() > 0 &&
         vertex.vertex().chi2() < parameters.maxVertexChi2 && vertex.vertex().z() >= parameters.minZ &&
         vertex.has_pv() && vertex.pv().position.z >= parameters.minZ;
}
