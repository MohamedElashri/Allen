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
#include "TwoKsLine.cuh"

INSTANTIATE_LINE(two_ks_line::two_ks_line_t, two_ks_line::Parameters)

__device__ float two_ks_line::two_ks_line_t::m(
  const Allen::Views::Physics::CompositeParticle& vertex1,
  const Allen::Views::Physics::CompositeParticle& vertex2)
{
  const auto v1track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex1.child(0));
  const auto v1track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex1.child(1));
  const auto pi1_ks1 = v1track1->state();
  const auto pi2_ks1 = v1track2->state();
  const auto v2track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex2.child(0));
  const auto v2track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex2.child(1));
  const auto pi1_ks2 = v2track1->state();
  const auto pi2_ks2 = v2track2->state();
  const float Dz_px = pi1_ks1.px() + pi2_ks1.px() + pi1_ks2.px() + pi2_ks2.px();
  const float Dz_py = pi1_ks1.py() + pi2_ks1.py() + pi1_ks2.py() + pi2_ks2.py();
  const float Dz_pz = pi1_ks1.pz() + pi2_ks1.pz() + pi1_ks2.pz() + pi2_ks2.pz();
  const float Dz_E = sqrtf(
                       Allen::mPi * Allen::mPi + pi1_ks1.px() * pi1_ks1.px() + pi1_ks1.py() * pi1_ks1.py() +
                       pi1_ks1.pz() * pi1_ks1.pz()) +
                     sqrtf(
                       Allen::mPi * Allen::mPi + pi2_ks1.px() * pi2_ks1.px() + pi2_ks1.py() * pi2_ks1.py() +
                       pi2_ks1.pz() * pi2_ks1.pz()) +
                     sqrtf(
                       Allen::mPi * Allen::mPi + pi1_ks2.px() * pi1_ks2.px() + pi1_ks2.py() * pi1_ks2.py() +
                       pi1_ks2.pz() * pi1_ks2.pz()) +
                     sqrtf(
                       Allen::mPi * Allen::mPi + pi2_ks2.px() * pi2_ks2.px() + pi2_ks2.py() * pi2_ks2.py() +
                       pi2_ks2.pz() * pi2_ks2.pz());
  return sqrtf(Dz_E * Dz_E - Dz_px * Dz_px - Dz_py * Dz_py - Dz_pz * Dz_pz);
}

__device__ void two_ks_line::two_ks_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  // Unpack the tuple.
  const auto ks_pair = std::get<0>(input);
  // take just one child
  const auto ks1 = static_cast<const Allen::Views::Physics::CompositeParticle*>(ks_pair.child(0));
  const auto ks2 = static_cast<const Allen::Views::Physics::CompositeParticle*>(ks_pair.child(1));

  const auto ks1trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks1->child(0));
  const auto ks1trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks1->child(1));
  const auto& ks1state1 = ks1trk1->state();
  const auto& ks1state2 = ks1trk2->state();

  const auto ks2trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks2->child(0));
  const auto ks2trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks2->child(1));
  const auto& ks2state1 = ks2trk1->state();
  const auto& ks2state2 = ks2trk2->state();

  const float cos1 =
    (ks1state1.px() * ks1state2.px() + ks1state1.py() * ks1state2.py() + ks1state1.pz() * ks1state2.pz()) /
    (ks1state1.p() * ks1state2.p());

  const float cos2 =
    (ks2state1.px() * ks2state2.px() + ks2state1.py() * ks2state2.py() + ks2state1.pz() * ks2state2.pz()) /
    (ks2state1.p() * ks2state2.p());

  if (sel) {
    parameters.dev_pt_pi1_ks1[index] = ks1state1.pt();
    parameters.dev_pt_pi2_ks1[index] = ks1state2.pt();
    parameters.dev_p_pi1_ks1[index] = ks1state1.p();
    parameters.dev_p_pi2_ks1[index] = ks1state2.p();
    parameters.dev_ipchi2_pi1_ks1[index] = ks1trk1->ip_chi2();
    parameters.dev_ipchi2_pi2_ks1[index] = ks1trk2->ip_chi2();
    parameters.dev_ip_pi1_ks1[index] = ks1trk1->ip();
    parameters.dev_ip_pi2_ks1[index] = ks1trk2->ip();

    parameters.dev_pt_pi1_ks2[index] = ks2state1.pt();
    parameters.dev_pt_pi2_ks2[index] = ks2state2.pt();
    parameters.dev_p_pi1_ks2[index] = ks2state1.p();
    parameters.dev_p_pi2_ks2[index] = ks2state2.p();
    parameters.dev_ipchi2_pi1_ks2[index] = ks2trk1->ip_chi2();
    parameters.dev_ipchi2_pi2_ks2[index] = ks2trk2->ip_chi2();
    parameters.dev_ip_pi1_ks2[index] = ks2trk1->ip();
    parameters.dev_ip_pi2_ks2[index] = ks2trk2->ip();

    parameters.dev_cos_open_pi_ks1[index] = cos1;
    parameters.dev_ip_ks1[index] = ks1->ip();
    parameters.dev_ip_comb_ks1[index] = ks1trk1->ip() * ks1trk2->ip() / ks1->ip();
    parameters.dev_pt_ks1[index] = ks1->vertex().pt();
    parameters.dev_chi2vtx_ks1[index] = ks1->vertex().chi2();
    parameters.dev_ipchi2_ks1[index] = -1.; // ks1->ip_chi2();
    parameters.dev_dira_ks1[index] = ks1->dira();
    parameters.dev_eta_ks1[index] = ks1->eta();
    parameters.dev_mks1[index] = ks1->mdipi();
    parameters.dev_cos_open_pi_ks2[index] = cos2;
    parameters.dev_ip_ks2[index] = ks2->ip();
    parameters.dev_ip_comb_ks2[index] = ks2trk1->ip() * ks2trk2->ip() / ks2->ip();
    parameters.dev_pt_ks2[index] = ks2->vertex().pt();
    parameters.dev_chi2vtx_ks2[index] = ks2->vertex().chi2();
    parameters.dev_ipchi2_ks2[index] = -1.; // ks2->ip_chi2();
    parameters.dev_dira_ks2[index] = ks2->dira();
    parameters.dev_eta_ks2[index] = ks2->eta();
    parameters.dev_mks2[index] = ks2->mdipi();
    parameters.dev_mks_pair[index] = m(*ks1, *ks2);

    parameters.dev_pv1x[index] = ks1->pv().position.x;
    parameters.dev_pv1y[index] = ks1->pv().position.y;
    parameters.dev_pv1z[index] = ks1->pv().position.z;
    parameters.dev_pv2x[index] = ks2->pv().position.x;
    parameters.dev_pv2y[index] = ks2->pv().position.y;
    parameters.dev_pv2z[index] = ks2->pv().position.z;
    parameters.dev_sv1x[index] = ks1->vertex().x();
    parameters.dev_sv1y[index] = ks1->vertex().y();
    parameters.dev_sv1z[index] = ks1->vertex().z();
    parameters.dev_sv2x[index] = ks2->vertex().x();
    parameters.dev_sv2y[index] = ks2->vertex().y();
    parameters.dev_sv2z[index] = ks2->vertex().z();
    parameters.dev_doca1_pi[index] = ks1->doca12();
    parameters.dev_doca2_pi[index] = ks2->doca12();
    parameters.dev_px_ks1[index] = ks1->vertex().px();
    parameters.dev_py_ks1[index] = ks1->vertex().py();
    parameters.dev_pz_ks1[index] = ks1->vertex().pz();
    parameters.dev_px_ks2[index] = ks2->vertex().px();
    parameters.dev_py_ks2[index] = ks2->vertex().py();
    parameters.dev_pz_ks2[index] = ks2->vertex().pz();
    parameters.dev_chi2trk_pi1_ks1[index] = ks1trk1->chi2() / ks1trk1->ndof();
    parameters.dev_chi2trk_pi2_ks1[index] = ks1trk2->chi2() / ks1trk2->ndof();
    parameters.dev_chi2trk_pi1_ks2[index] = ks2trk1->chi2() / ks2trk1->ndof();
    parameters.dev_chi2trk_pi2_ks2[index] = ks2trk2->chi2() / ks2trk2->ndof();

    parameters.dev_decision[index] = sel;
  }
}

__device__ bool two_ks_line::two_ks_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  // Unpack the tuple.
  const auto ks_pair = std::get<0>(input);
  const auto ks1 = static_cast<const Allen::Views::Physics::CompositeParticle*>(ks_pair.child(0));
  const auto ks2 = static_cast<const Allen::Views::Physics::CompositeParticle*>(ks_pair.child(1));

  const bool ks1_opposite_sign = ks1->charge() == 0;
  const bool ks2_opposite_sign = ks2->charge() == 0;

  if (ks1_opposite_sign != parameters.OppositeSign || ks2_opposite_sign != parameters.OppositeSign) return false;
  // Get the first vertex decision.
  // Vertex quality cuts.
  bool dec1 = ks1->vertex().chi2() > 0 && ks1->vertex().chi2() < parameters.maxVertexChi2;
  if (!dec1) return false;
  // Kinematic cuts.
  dec1 &= ks1->minpt() > parameters.minTrackPt_piKs;
  dec1 &= ks1->minp() > parameters.minTrackP_piKs;
  dec1 &= ks1->mdipi() > parameters.minM_Ks;
  dec1 &= ks1->mdipi() < parameters.maxM_Ks;
  dec1 &= ks1->vertex().pt() > parameters.minComboPt_Ks;
  if (!dec1) return false;
  // PV cuts.
  dec1 &= ks1->eta() > parameters.minEta_Ks;
  dec1 &= ks1->eta() < parameters.maxEta_Ks;
  dec1 &= ks1->minipchi2() > parameters.minTrackIPChi2_Ks;
  dec1 &= ks1->dira() > parameters.minCosDira;
  if (!dec1) return false;
  // Cuts that need constituent tracks.
  const auto v1track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks1->child(0));
  const auto v1track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks1->child(1));
  const auto v1state1 = v1track1->state();
  const auto v1state2 = v1track2->state();
  const float cos1 = (v1state1.px() * v1state2.px() + v1state1.py() * v1state2.py() + v1state1.pz() * v1state2.pz()) /
                     (v1state1.p() * v1state2.p());
  dec1 &= cos1 > parameters.minCosOpening;
  const float v1ip1 = v1track1->ip();
  const float v1ip2 = v1track2->ip();
  const float v1ip = ks1->ip();
  dec1 &= v1ip1 * v1ip2 / v1ip > parameters.min_combip;
  if (!dec1) return false;

  // Get the second vertex decision.
  // Vertex quality cuts.
  bool dec2 = ks2->vertex().chi2() > 0 && ks2->vertex().chi2() < parameters.maxVertexChi2;
  if (!dec2) return false;
  // Kinematic cuts.
  dec2 &= ks2->minpt() > parameters.minTrackPt_piKs;
  dec2 &= ks2->minp() > parameters.minTrackP_piKs;
  dec2 &= ks2->mdipi() > parameters.minM_Ks;
  dec2 &= ks2->mdipi() < parameters.maxM_Ks;
  dec2 &= ks2->vertex().pt() > parameters.minComboPt_Ks;
  if (!dec2) return false;
  // PV cuts.
  dec2 &= ks2->eta() > parameters.minEta_Ks;
  dec2 &= ks2->eta() < parameters.maxEta_Ks;
  dec2 &= ks2->minipchi2() > parameters.minTrackIPChi2_Ks;
  dec2 &= ks2->dira() > parameters.minCosDira;
  if (!dec2) return false;
  // Cuts that need constituent tracks.
  const auto v2track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks2->child(0));
  const auto v2track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks2->child(1));
  const auto v2state1 = v2track1->state();
  const auto v2state2 = v2track2->state();
  const float cos2 = (v2state1.px() * v2state2.px() + v2state1.py() * v2state2.py() + v2state1.pz() * v2state2.pz()) /
                     (v2state1.p() * v2state2.p());
  dec2 &= cos2 > parameters.minCosOpening;
  const float v2ip1 = v2track1->ip();
  const float v2ip2 = v2track2->ip();
  const float v2ip = ks2->ip();
  dec2 &= v2ip1 * v2ip2 / v2ip > parameters.min_combip;

  return dec1 && dec2;
}
