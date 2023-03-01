/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DiMuonDrellYanLine.cuh"

INSTANTIATE_LINE(di_muon_drell_yan_line::di_muon_drell_yan_line_t, di_muon_drell_yan_line::Parameters)

__device__ bool di_muon_drell_yan_line::di_muon_drell_yan_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto& particle = std::get<0>(input);

  const bool opposite_sign = particle.charge() == 0;
  if (opposite_sign != parameters.OppositeSign) return false;

  const auto& vertex = particle.vertex();

  if (vertex.chi2() < 0) {
    return false; // this should never happen.
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  const bool decision = particle.is_dimuon() && vertex.chi2() <= parameters.maxVertexChi2 &&
                        particle.doca12() <= parameters.maxDoca && trk1->state().pt() >= parameters.minTrackPt &&
                        trk1->state().p() >= parameters.minTrackP && trk1->state().eta() <= parameters.maxTrackEta

                        && trk2->state().pt() >= parameters.minTrackPt && trk2->state().p() >= parameters.minTrackP &&
                        trk2->state().eta() <= parameters.maxTrackEta

                        && particle.mdimu() >= parameters.minMass && particle.mdimu() <= parameters.maxMass

                        && particle.pv().position.z >= parameters.minZ;

  return decision;
}
