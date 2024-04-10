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
#include "SMOG2_DiTrack.cuh"

INSTANTIATE_LINE(SMOG2_ditrack_line::SMOG2_ditrack_line_t, SMOG2_ditrack_line::Parameters)

__device__ bool SMOG2_ditrack_line::SMOG2_ditrack_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto& vtx = std::get<0>(input);
  if (vtx.vertex().chi2() < 0) {
    return false;
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(1));

  const bool trk1_decision = trk1->state().z() < parameters.maxZ && trk1->state().z() >= parameters.minZ &&
                             trk1->state().p() > parameters.minTrackP && trk1->state().pt() > parameters.minTrackPt &&
                             trk1->state().eta() > parameters.minEta && trk1->state().eta() < parameters.maxEta &&
                             trk1->chi2() / trk1->ndof() < parameters.maxTrackChi2Ndf && trk1->has_pv() &&
                             trk1->ip_chi2() > parameters.minTrackIPCHI2 &&
                             trk1->ip_chi2() < parameters.maxTrackIPCHI2 &&
                             trk1->track().ghost_probability() < parameters.maxGhostProb;
  const bool trk2_decision = trk2->state().z() < parameters.maxZ && trk2->state().z() >= parameters.minZ &&
                             trk2->state().p() > parameters.minTrackP && trk2->state().pt() > parameters.minTrackPt &&
                             trk2->state().eta() > parameters.minEta && trk2->state().eta() < parameters.maxEta &&
                             trk2->chi2() / trk2->ndof() < parameters.maxTrackChi2Ndf && trk2->has_pv() &&
                             trk2->ip_chi2() > parameters.minTrackIPCHI2 &&
                             trk2->ip_chi2() < parameters.maxTrackIPCHI2 &&
                             trk2->track().ghost_probability() < parameters.maxGhostProb;

  if (not trk1_decision or not trk2_decision) {
    return false;
  }

  const bool mass_decision =
    parameters.mMother < 0.f ?
      true :
      min(
        fabsf(vtx.m12(parameters.m1, parameters.m2) - parameters.mMother),
        fabsf(vtx.m12(parameters.m2, parameters.m1) - parameters.mMother)) < parameters.massWindow &&
        vtx.charge() == parameters.combCharge;

  bool decision = mass_decision && vtx.vertex().z() < parameters.maxZ && vtx.vertex().z() >= parameters.minZ &&
                  vtx.maxpt() > parameters.minEitherTrackPt && vtx.vertex().chi2() < parameters.maxVertexChi2 &&
                  vtx.mdipi() > parameters.minMdipion && vtx.doca12() <= parameters.maxDoca;
  if (vtx.has_pv())
    decision = decision && vtx.pv().position.z < parameters.maxZ && vtx.pv().position.z >= parameters.minZ &&
               vtx.fdchi2() > parameters.minFDCHI2 && vtx.fdchi2() < parameters.maxFDCHI2;

  return decision;
}

__device__ void SMOG2_ditrack_line::SMOG2_ditrack_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto particle = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  if (sel) {
    parameters.sv_masses[index] = parameters.mMother < 0.f ?
                                    true :
                                    min(
                                      fabsf(particle.m12(parameters.m1, parameters.m2) - parameters.mMother),
                                      fabsf(particle.m12(parameters.m2, parameters.m1) - parameters.mMother));

    parameters.track1pt[index] = track1->state().pt();
    parameters.track2pt[index] = track2->state().pt();
    parameters.minipchi2[index] = particle.minipchi2();
    parameters.ip[index] = particle.ip();
  }
}
