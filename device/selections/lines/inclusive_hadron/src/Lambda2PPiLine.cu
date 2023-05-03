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
  const auto c0_state = c0->state(), c1_state = c1->state();

  const auto c0_is_proton = c0_state.p() > c1_state.p();
  auto L_M = 9999.f, p_P = 0.f, p_PT = 0.f, p_ipchi2 = 0.f, pi_ipchi2 = 0.f;
  if (c0_is_proton) {
    L_M = particle.m12(Allen::mP, Allen::mPi);
    p_P = c0_state.p();
    p_PT = c0_state.pt();
    p_ipchi2 = c0->ip_chi2();
    pi_ipchi2 = c1->ip_chi2();
  }
  else {
    L_M = particle.m12(Allen::mPi, Allen::mP);
    p_P = c1_state.p();
    p_PT = c1_state.pt();
    p_ipchi2 = c1->ip_chi2();
    pi_ipchi2 = c0->ip_chi2();
  }

  const bool decision = L_M < parameters.L_M_max && p_ipchi2 > parameters.p_MIPCHI2_min &&
                        pi_ipchi2 > parameters.pi_MIPCHI2_min && p_P > parameters.p_P_min &&
                        p_PT > parameters.p_PT_min && vertex.chi2() < parameters.L_VCHI2_max &&
                        parameters.L_VZ_min < vertex.z() && vertex.z() < parameters.L_VZ_max &&
                        particle.doca12() < parameters.p_pi_DOCA_max && vertex.pt() > parameters.L_PT_min &&
                        particle.fdchi2() > parameters.L_BPVVDCHI2_min && particle.dz() > parameters.L_BPVVDZ_min &&
                        particle.drho() > parameters.L_BPVVDRHO_min && particle.dira() > parameters.L_BPVDIRA_min;

  return decision;
}

__device__ void lambda2ppi_line::lambda2ppi_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto vertex = particle.vertex();
    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0)),
               c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));
    const auto c0_state = c0->state(), c1_state = c1->state();

    const auto c0_is_proton = c0_state.p() > c1_state.p();
    if (c0_is_proton) {
      // don't touch this
      parameters.L_M[index] = particle.m12(Allen::mP, Allen::mPi);
      // don't touch this
      parameters.p_P[index] = c0_state.p();
      // don't touch this
      parameters.p_PT[index] = c0_state.pt();
      // tunable, should be significantly smaller than pi_MIPCHI2. best to tune them together
      parameters.p_MIPCHI2[index] = c0->ip_chi2();
      // no cut to be tuned here. only for monitoring
      parameters.pi_P[index] = c1_state.p();
      // only for monitoring
      parameters.pi_PT[index] = c1_state.pt();
      // tunable, should be significantly larger than p_MIPCHI2. best to tune them together
      parameters.pi_MIPCHI2[index] = c1->ip_chi2();
    }
    else { // see comments above
      parameters.L_M[index] = particle.m12(Allen::mPi, Allen::mP);
      parameters.p_P[index] = c1_state.p();
      parameters.p_PT[index] = c1_state.pt();
      parameters.p_MIPCHI2[index] = c1->ip_chi2();
      parameters.pi_P[index] = c0_state.p();
      parameters.pi_PT[index] = c0_state.pt();
      parameters.pi_MIPCHI2[index] = c0->ip_chi2();
    }
    // already quite tight
    parameters.L_VCHI2[index] = vertex.chi2();
    // better not go tighter as we don't have a full blown track propagation and would loose some of the Lambdas where p
    // and pi only leave hits in the most downstream Velo modules
    parameters.p_pi_DOCA[index] = particle.doca12();
    // tunable. shouldn't go far beyond 2 GeV though
    parameters.L_PT[index] = vertex.pt();
    // tunable. correlated with MIPCHI2s and DZ, DRHO below
    parameters.L_BPVVDCHI2[index] = particle.fdchi2();
    // tunable. correlated with MIPCHI2s and VDCHI2
    parameters.L_BPVVDZ[index] = particle.dz();
    // kind of tunable. correlated with MIPCHI2s and VDCHI2
    parameters.L_BPVVDRHO[index] = particle.drho();
    // tunable up to ~0.9999.
    parameters.L_BPVDIRA[index] = particle.dira();
  }
}