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
#include "XiOmegaLLLLine.cuh"

INSTANTIATE_LINE(xi_omega_lll_line::xi_omega_lll_line_t, xi_omega_lll_line::Parameters)

__device__ bool xi_omega_lll_line::xi_omega_lll_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto XimOmmt = std::get<0>(input);
  const auto XimOmm = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(XimOmmt.child(0));
  const auto Lambda = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(XimOmm->child(0));
  const auto vertex = XimOmmt.vertex();
  const auto XimOmm_vx = XimOmm->vertex();
  const auto L_vx = Lambda->vertex();
  const auto companion = Allen::dyn_cast<const Allen::Views::Physics::BasicParticle*>(XimOmmt.child(1));
  const auto XimOmm_track = Allen::dyn_cast<const Allen::Views::Physics::BasicParticle*>(XimOmm->child(1));
  const auto companion_state = companion->state();
  const auto XimOmm_track_state = XimOmm_track->state();
  // Proton is always the child with larger momentum
  const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(0)),
             c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(1));
  const auto c0_state = c0->state(), c1_state = c1->state();
  const bool c0_is_proton = c0_state.p() > c1_state.p();
  const auto mL = c0_is_proton ? Lambda->m12(Allen::mP, Allen::mPi) : Lambda->m12(Allen::mPi, Allen::mP);
  const bool charge_requirement =
    c0_is_proton ? (XimOmm_track_state.charge() == c1_state.charge() && companion_state.charge() == c0_state.charge()) :
                   (XimOmm_track_state.charge() == c0_state.charge() && companion_state.charge() == c1_state.charge());
  return properties.L_M_min < mL && mL < properties.L_M_max && charge_requirement &&
         L_vx.chi2() < properties.L_VCHI2_max && Lambda->doca12() < properties.L_DOCA_max &&
         ((properties.Xi_M_min < XimOmm->m12(Allen::mL, Allen::mPi) &&
           XimOmm->m12(Allen::mL, Allen::mPi) < properties.Xi_M_max &&
           XimOmmt.m12(Allen::mXi, Allen::mMu) < properties.XimOmmt_M_max) ||
          (properties.Omega_M_min < XimOmm->m12(Allen::mL, Allen::mK) &&
           XimOmm->m12(Allen::mL, Allen::mK) < properties.Omega_M_max &&
           XimOmmt.m12(Allen::mOmega, Allen::mMu) < properties.XimOmmt_M_max)) &&
         companion_state.pt() > properties.t_PT_min && companion->ip_chi2() > properties.t_MIPCHI2_min &&
         L_vx.z() - XimOmm_vx.z() > properties.LVDZ_min && XimOmm_vx.z() - vertex.z() > properties.XimOmmVDZ_min &&
         properties.VZ_min < vertex.z() && vertex.z() < properties.VZ_max &&
         XimOmmt.pv().position.z > properties.BPVZ_min && XimOmm->dz() > properties.BPVVDZ_min &&
         XimOmm->drho() > properties.BPVVDRHO_min;
}

__device__ bool xi_omega_lll_line::xi_omega_lll_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto XimOmmt = std::get<0>(input);
    const auto XimOmm = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(XimOmmt.child(0));
    const auto Lambda = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(XimOmm->child(0));
    const auto vertex = XimOmmt.vertex();
    const auto XimOmm_vx = XimOmm->vertex();
    const auto L_vx = Lambda->vertex();
    const auto companion = Allen::dyn_cast<const Allen::Views::Physics::BasicParticle*>(XimOmmt.child(1));
    const auto XimOmm_track = Allen::dyn_cast<const Allen::Views::Physics::BasicParticle*>(XimOmm->child(1));
    const auto companion_state = companion->state();
    const auto XimOmm_track_state = XimOmm_track->state();
    // Proton is always the child with larger momentum
    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(0)),
               c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(1));
    const bool c0_is_proton = c0->state().p() > c1->state().p();
    const auto proton = c0_is_proton ? c0 : c1, pion = c0_is_proton ? c1 : c0;
    const auto proton_state = proton->state(), pion_state = pion->state();
    const auto mL = c0_is_proton ? Lambda->m12(Allen::mP, Allen::mPi) : Lambda->m12(Allen::mPi, Allen::mP);

    parameters.Xipi_M[index] = XimOmmt.m12(Allen::mXi, Allen::mPi);
    parameters.Omegapi_M[index] = XimOmmt.m12(Allen::mOmega, Allen::mK);
    parameters.PT[index] = vertex.pt();
    parameters.DOCA[index] = XimOmmt.doca12();
    parameters.VZ[index] = vertex.z();
    parameters.BPVVDZ[index] = XimOmmt.dz();
    parameters.BPVVDRHO[index] = XimOmmt.drho();
    parameters.BPVDIRA[index] = XimOmmt.dira();
    parameters.BPVIP[index] = XimOmmt.ip();
    parameters.BPVFD[index] = XimOmmt.fd();
    parameters.Xi_M[index] = XimOmm->m12(Allen::mL, Allen::mPi);
    parameters.Omega_M[index] = XimOmm->m12(Allen::mL, Allen::mK);
    parameters.XimOmm_PT[index] = XimOmm_vx.pt();
    parameters.XimOmm_DOCA[index] = XimOmm->doca12();
    parameters.XimOmm_VZ[index] = XimOmm_vx.z();
    parameters.XimOmm_BPVVDZ[index] = XimOmm->dz();
    parameters.XimOmm_BPVVDRHO[index] = XimOmm->drho();
    parameters.XimOmm_BPVDIRA[index] = XimOmm->dira();
    parameters.XimOmm_BPVIP[index] = XimOmm->ip();
    parameters.XimOmm_BPVFD[index] = XimOmm->fd();
    parameters.t_P[index] = companion_state.p();
    parameters.t_PT[index] = companion_state.pt();
    parameters.t_MIPCHI2[index] = companion->ip_chi2();
    parameters.t_MIP[index] = companion->ip();
    parameters.t_CHI2NDF[index] = companion->chi2() / companion->ndof();
    parameters.t_Q[index] = companion_state.charge();
    parameters.XimOmm_t_P[index] = XimOmm_track_state.p();
    parameters.XimOmm_t_PT[index] = XimOmm_track_state.pt();
    parameters.XimOmm_t_MIPCHI2[index] = XimOmm_track->ip_chi2();
    parameters.XimOmm_t_MIP[index] = XimOmm_track->ip();
    parameters.XimOmm_t_CHI2NDF[index] = XimOmm_track->chi2() / XimOmm_track->ndof();
    parameters.XimOmm_t_Q[index] = XimOmm_track_state.charge();
    parameters.L_M[index] = mL;
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

__device__ void xi_omega_lll_line::xi_omega_lll_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto XimOmmt = std::get<0>(input);
    const auto XimOmm = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(XimOmmt.child(0));
    const auto Lambda = Allen::dyn_cast<const Allen::Views::Physics::CompositeParticle*>(XimOmm->child(0));
    // Proton is always the child with larger momentum
    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(0)),
               c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(1));
    const auto mLpi = XimOmm->m12(Allen::mL, Allen::mPi);
    const auto mLK = XimOmm->m12(Allen::mL, Allen::mK);
    const auto mL =
      c0->state().p() > c1->state().p() ? Lambda->m12(Allen::mP, Allen::mPi) : Lambda->m12(Allen::mPi, Allen::mP);

    properties.histogram_Lambda_mass.increment(mL);
    properties.histogram_Xi_mass.increment(mLpi);
    properties.histogram_Omega_mass.increment(mLK);
  }
}
