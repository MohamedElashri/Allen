/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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

  const bool mass_decision =
    parameters.mMother < 0.f ?
      true :
      fabsf(min(vtx.m12(parameters.m1, parameters.m2), vtx.m12(parameters.m2, parameters.m1)) - parameters.mMother) <
          parameters.massWindow &&
        fabsf(vtx.charge() - parameters.combCharge) < 0.01;

  bool decision = vtx.vertex().z() < parameters.maxZ && vtx.vertex().z() >= parameters.minZ &&
                  vtx.maxp() > parameters.minTrackP && vtx.maxpt() > parameters.minTrackPt &&
                  trk1->chi2() / trk1->ndof() < parameters.maxTrackChi2Ndf &&
                  trk2->chi2() / trk2->ndof() < parameters.maxTrackChi2Ndf &&
                  vtx.vertex().chi2() < parameters.maxVertexChi2 && vtx.doca12() <= parameters.maxDoca && mass_decision;
  if (vtx.has_pv()) decision = decision && vtx.pv().position.z < parameters.maxZ;

  return decision;
}
