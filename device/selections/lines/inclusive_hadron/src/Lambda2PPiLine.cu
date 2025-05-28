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
#include "Lambda2PPiLine.cuh"

INSTANTIATE_LINE(lambda2ppi_line::lambda2ppi_line_t, lambda2ppi_line::Parameters)

__device__ bool lambda2ppi_line::lambda2ppi_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto Lambda = std::get<0>(input);
  const bool pv_filter =
    Lambda.has_pv() && Lambda.pv().position.z >= properties.minPVZ && Lambda.pv().position.z < properties.maxPVZ;

  const auto L_vx = Lambda.vertex();
  // Proton is always first child for anything that passes the cuts below (see FilterTracks -- the ordering is
  // propagated through VertexFitter)
  const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda.child(0)),
             c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda.child(1));
  const auto proton = c0->state().p() > c1->state().p() ? c0 : c1;
  const auto pion = c0->state().p() > c1->state().p() ? c1 : c0;
  const auto lambda_mass =
    c0->state().p() > c1->state().p() ? Lambda.m12(Allen::mP, Allen::mPi) : Lambda.m12(Allen::mPi, Allen::mP);
  const auto proton_state = proton->state(), pion_state = pion->state();

  // Repeat stuff from FilterTracks, TODO: have container with lambda-prfilter decisions (will be needed so that
  // Lambda+track combinatorics doesn't explode)
  const bool track_filter = proton_state.charge() != pion_state.charge() && proton_state.pt() > properties.L_p_PT_min &&
                            proton->has_pv() && proton->ip_chi2() > properties.L_p_MIPCHI2_min &&
                            proton->ip() > properties.L_p_MIP_min && pion_state.pt() > properties.L_pi_PT_min &&
                            pion->ip_chi2() > properties.L_pi_MIPCHI2_min && pion->ip() > properties.L_pi_MIP_min &&
                            Lambda.doca12() < properties.L_DOCA_max && L_vx.pt() > properties.L_PT_min &&
                            lambda_mass < properties.L_M_max;

  return pv_filter && track_filter && L_vx.chi2() < properties.L_VCHI2_max && properties.L_VZ_min < L_vx.z() &&
         L_vx.z() < properties.L_VZ_max && Lambda.dz() > properties.L_BPVVDZ_min &&
         Lambda.drho() > properties.L_BPVVDRHO_min && Lambda.fdchi2() > properties.L_BPVVDCHI2_min &&
         Lambda.dira() > properties.L_BPVDIRA_min;
}

__device__ bool lambda2ppi_line::lambda2ppi_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto Lambda = std::get<0>(input);
    const auto vertex = Lambda.vertex();
    // Proton is always the child with larger momentum
    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda.child(0)),
               c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda.child(1));
    const auto proton = c0->state().p() > c1->state().p() ? c0 : c1;
    const auto pion = c0->state().p() > c1->state().p() ? c1 : c0;
    const auto proton_state = proton->state(), pion_state = pion->state();

    // tunable if needed be down to 1135 MeV
    parameters.L_M[index] =
      c0->state().p() > c1->state().p() ? Lambda.m12(Allen::mP, Allen::mPi) : Lambda.m12(Allen::mPi, Allen::mP);
    parameters.p_P[index] = proton_state.p();
    parameters.p_PT[index] = proton_state.pt();
    // tunable up to 16, should be significantly smaller than pi_MIPCHI2. best to tune them together pi up to 42
    parameters.p_MIPCHI2[index] = proton->ip_chi2();
    parameters.p_MIP[index] = proton->ip();
    // globally tunable
    parameters.p_CHI2NDF[index] = proton->chi2() / proton->ndof();
    parameters.p_Q[index] = proton_state.charge();
    parameters.pi_P[index] = pion_state.p();
    // This is what makes the Lambda line orthogonal to the TrackMVA lines. Tunable (if really needed) to 200 MeV in
    // FilterTracks alg.
    parameters.pi_PT[index] = pion_state.pt();
    // tunable, should be significantly larger than p_MIPCHI2. best to tune them together
    parameters.pi_MIPCHI2[index] = pion->ip_chi2();
    parameters.pi_MIP[index] = pion->ip();
    parameters.pi_CHI2NDF[index] = pion->chi2() / pion->ndof();
    parameters.pi_Q[index] = pion_state.charge();
    // tunable down to 8
    parameters.L_VCHI2[index] = vertex.chi2();
    // better not go tighter as we don't have a full blown track propagation and would loose some of the Lambdas where p
    // and pi only leave hits in the most downstream Velo modules
    parameters.p_pi_DOCA[index] = Lambda.doca12();
    parameters.L_PT[index] = vertex.pt();
    parameters.L_BPVVDCHI2[index] = Lambda.fdchi2();
    // tunable up to 40 mm
    parameters.L_BPVVDZ[index] = Lambda.dz();
    // tunable up to 3.2 mm
    parameters.L_BPVVDRHO[index] = Lambda.drho();
    // tunable up to 0.9998
    parameters.L_BPVDIRA[index] = Lambda.dira();
    parameters.L_VZ[index] = Lambda.vertex().z();
  }
  return sel;
}

__device__ void lambda2ppi_line::lambda2ppi_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  const auto lz = std::get<0>(input);
  if (sel) {

    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(lz.child(0));
    const auto c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(lz.child(1));
    const auto mass = c0->state().p() > c1->state().p() ? lz.m12(Allen::mP, Allen::mPi) : lz.m12(Allen::mPi, Allen::mP);

    properties.histogram_lz_mass.increment(mass);
    properties.histogram_lz_pt.increment(lz.vertex().pt());
    properties.histogram_lz_svz.increment(lz.vertex().z());
    properties.histogram_lz_pvz.increment(lz.pv().position.z);
  }
}
