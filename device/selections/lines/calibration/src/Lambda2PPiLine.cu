/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "Lambda2PPiLine.cuh"

INSTANTIATE_LINE(lambda2ppi_line::lambda2ppi_line_t, lambda2ppi_line::Parameters)

__device__ bool lambda2ppi_line::lambda2ppi_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const auto vertex = particle.vertex();
  if (vertex.chi2() < 0) return false;
  const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0)),
             c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));
  // TODO: how to get the state closest to the Lambda decay vertex?
  const auto c0_state = c0->state(), c1_state = c1->state();

  const auto c0_is_proton = c0_state.p() > c1_state.p();
  auto L_M = 9999.f, p_P = 0.f, pi_P = 0.f, p_PT = 0.f, pi_PT = 0.f, p_ipchi2 = 0.f, pi_ipchi2 = 0.f;
  if (c0_is_proton) {
    L_M = particle.m12(Allen::mP, Allen::mPi);
    p_P = c0_state.p();
    p_PT = c0_state.pt();
    p_ipchi2 = c0->ip_chi2();
    pi_P = c1_state.p();
    pi_PT = c1_state.pt();
    pi_ipchi2 = c1->ip_chi2();
  }
  else {
    L_M = particle.m12(Allen::mPi, Allen::mP);
    p_P = c1_state.p();
    p_PT = c1_state.pt();
    p_ipchi2 = c1->ip_chi2();
    pi_P = c0_state.p();
    pi_PT = c0_state.pt();
    pi_ipchi2 = c0->ip_chi2();
  }

  const bool decision = L_M < parameters.L_M_max && p_ipchi2 > parameters.p_BPVIPCHI2_min &&
                        pi_ipchi2 > parameters.pi_BPVIPCHI2_min && p_P > parameters.p_P_min &&
                        p_PT > parameters.p_PT_min && p_P - pi_P > parameters.diff_P_min &&
                        p_PT - pi_PT > parameters.diff_PT_min && vertex.chi2() < parameters.L_VCHI2_max &&
                        particle.doca12() < parameters.p_pi_DOCA_max && vertex.pt() > parameters.L_PT_min &&
                        particle.fdchi2() > parameters.L_BPVVDCHI2_min && particle.dz() > parameters.L_BPVVDZ_min &&
                        particle.drho() > parameters.L_BPVVDRHO_min;

  return decision;
}
