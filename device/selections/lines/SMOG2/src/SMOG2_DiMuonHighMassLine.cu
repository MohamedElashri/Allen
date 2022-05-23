/*****************************************************************************\
 * (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_DiMuonHighMassLine.cuh"

INSTANTIATE_LINE(SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t, SMOG2_dimuon_highmass_line::Parameters)

__device__ bool SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto& vtx = std::get<0>(input);
  if (vtx.vertex().chi2() < 0) {
    return false;
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(1));

  bool decision = vtx.vertex().z() < parameters.maxZ && vtx.is_dimuon() && vtx.doca12() < parameters.maxDoca &&
                  trk1->chi2() / trk1->ndof() < parameters.maxTrackChi2Ndf &&
                  trk2->chi2() / trk2->ndof() < parameters.maxTrackChi2Ndf && vtx.mdimu() >= parameters.minMass &&
                  vtx.minpt() >= parameters.minTrackPt && vtx.minp() >= parameters.minTrackP &&
                  vtx.vertex().chi2() < parameters.maxVertexChi2 && vtx.vertex().z() >= parameters.minZ &&
                  fabsf(vtx.charge() - parameters.CombCharge) < 0.01;
  if (vtx.has_pv()) decision = decision && vtx.pv().position.z < parameters.maxZ;

  return decision;
}
