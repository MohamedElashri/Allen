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
#include "LambdaLLDetachedTrackLine.cuh"

INSTANTIATE_LINE(
  lambda_ll_detached_track_line::lambda_ll_detached_track_line_t,
  lambda_ll_detached_track_line::Parameters)

__device__ bool lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto Lt = std::get<0>(input);
  const auto vertex = Lt.vertex();
  const auto Lambda = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(Lt.child(0));
  const auto L_vx = Lambda->vertex();
  const auto companion = Allen::dyn_cast<const Allen::Views::Physics::BasicParticle*>(Lt.child(1));
  const auto companion_state = companion->state();
  // Proton is always the child with larger momentum
  const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(0)),
             c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(1));
  const auto c0_state = c0->state(), c1_state = c1->state();
  const bool c0_is_proton = c0_state.p() > c1_state.p();
  const auto mL = c0_is_proton ? Lambda->m12(Allen::mP, Allen::mPi) : Lambda->m12(Allen::mPi, Allen::mP);
  const auto proton = c0->state().p() > c1->state().p() ? c0 : c1;
  const auto pion = c0->state().p() > c1->state().p() ? c1 : c0;
  const auto proton_state = proton->state(), pion_state = pion->state();
  // let's require same charge as proton as there should always be at least one positive (negative) track in
  // a (anti-) charm decay. Decays from b should be covered by the generic lines.
  const bool track_and_proton_are_same_sign =
    c0_is_proton ? companion_state.charge() == c0_state.charge() : companion_state.charge() == c1_state.charge();
  return track_and_proton_are_same_sign && pion_state.pt() > properties.pi_PT_min &&
         proton_state.pt() > properties.p_PT_min && pion->ip_chi2() > properties.pi_MIPCHI2_min &&
         proton->ip_chi2() > properties.p_MIPCHI2_min && Lambda->doca12() < properties.L_DOCA_max &&
         L_vx.chi2() < properties.L_VCHI2_max && Lambda->fdchi2() > properties.L_BPVFDCHI2_min &&
         properties.L_M_min < mL && mL < properties.L_M_max && L_vx.pt() > properties.L_PT_min &&
         companion_state.pt() > properties.t_PT_min && companion->ip_chi2() > properties.t_MIPCHI2_min &&
         Lt.m12(Allen::mL, Allen::mPi) < properties.M_max && L_vx.z() - vertex.z() > properties.LVDZ_min &&
         properties.VZ_min < vertex.z() && vertex.z() < properties.VZ_max && Lt.dz() > properties.BPVVDZ_min &&
         Lt.drho() > properties.BPVVDRHO_min && L_vx.pt() + companion_state.pt() > properties.SUMPT_min;
}

__device__ bool lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto Lt = std::get<0>(input);
    const auto vertex = Lt.vertex();
    const auto Lambda = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(Lt.child(0));
    const auto companion = Allen::dyn_cast<const Allen::Views::Physics::BasicParticle*>(Lt.child(1));
    const auto companion_state = companion->state();
    parameters.M[index] = Lt.m12(Allen::mL, Allen::mPi);
    parameters.MCORR[index] = Lt.mcor();
    parameters.PT[index] = vertex.pt();
    parameters.DOCA[index] = Lt.doca12();
    parameters.VZ[index] = vertex.z();
    parameters.BPVVDZ[index] = Lt.dz();
    parameters.BPVVDRHO[index] = Lt.drho();
    parameters.BPVDIRA[index] = Lt.dira();
    parameters.BPVIP[index] = Lt.ip();
    parameters.BPVFD[index] = Lt.fd();
    parameters.t_P[index] = companion_state.p();
    parameters.t_PT[index] = companion_state.pt();
    parameters.t_MIPCHI2[index] = companion->ip_chi2();
    parameters.t_MIP[index] = companion->ip();
    parameters.t_CHI2NDF[index] = companion->chi2() / companion->ndof();
    parameters.t_Q[index] = companion_state.charge();

    const auto L_vx = Lambda->vertex();
    // Proton is always the child with larger momentum
    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(0)),
               c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(1));
    const auto proton = c0->state().p() > c1->state().p() ? c0 : c1;
    const auto pion = c0->state().p() > c1->state().p() ? c1 : c0;
    const auto proton_state = proton->state(), pion_state = pion->state();

    parameters.L_M[index] =
      c0->state().p() > c1->state().p() ? Lambda->m12(Allen::mP, Allen::mPi) : Lambda->m12(Allen::mPi, Allen::mP);
    parameters.p_P[index] = proton_state.p();
    parameters.p_PT[index] = proton_state.pt();
    parameters.p_MIPCHI2[index] = proton->ip_chi2();
    parameters.p_MIP[index] = proton->ip();
    parameters.p_CHI2NDF[index] = proton->chi2() / proton->ndof();
    parameters.p_Q[index] = proton_state.charge();
    parameters.pi_P[index] = pion_state.p();
    parameters.pi_PT[index] = pion_state.pt();
    parameters.pi_MIPCHI2[index] = pion->ip_chi2();
    parameters.pi_MIP[index] = pion->ip();
    parameters.pi_CHI2NDF[index] = pion->chi2() / pion->ndof();
    parameters.pi_Q[index] = pion_state.charge();
    parameters.L_VCHI2[index] = L_vx.chi2();
    parameters.L_VZ[index] = L_vx.z();
    parameters.p_pi_DOCA[index] = Lambda->doca12();
    parameters.L_PT[index] = L_vx.pt();
    parameters.L_BPVVDCHI2[index] = Lambda->fdchi2();
    parameters.L_BPVVDZ[index] = Lambda->dz();
    parameters.L_BPVVDRHO[index] = Lambda->drho();
    parameters.L_BPVDIRA[index] = Lambda->dira();
  }
  return sel;
}

__device__ void lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto Lt = std::get<0>(input);
    const auto Lambda = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(Lt.child(0));
    // Proton is always the child with larger momentum
    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(0)),
               c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(1));
    const auto mLpi = Lt.m12(Allen::mL, Allen::mPi);
    const auto mL =
      c0->state().p() > c1->state().p() ? Lambda->m12(Allen::mP, Allen::mPi) : Lambda->m12(Allen::mPi, Allen::mP);

    properties.histogram_Lambda_mass.increment(mL);
    properties.histogram_LambdaPi_mass.increment(mLpi);
  }
}
