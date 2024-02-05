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

void lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::init()
{
  Line<lambda_ll_detached_track_line::lambda_ll_detached_track_line_t, lambda_ll_detached_track_line::Parameters>::
    init();
#ifndef ALLEN_STANDALONE
  histogram_Lambda_mass = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                       "Lambda_mass_LambdaLLDetachedTrack",
                                                                       "m(p#pi^{#minus}) [MeV]",
                                                                       {property<histogram_Lambda_mass_nbins_t>(),
                                                                        property<histogram_Lambda_mass_min_t>(),
                                                                        property<histogram_Lambda_mass_max_t>()}},
                                                                      {}};
  histogram_LambdaPi_mass = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                         "LambdaPi_mass",
                                                                         "m(#Lambda#pi^{+}) [MeV]",
                                                                         {property<histogram_LambdaPi_mass_nbins_t>(),
                                                                          property<histogram_LambdaPi_mass_min_t>(),
                                                                          property<histogram_LambdaPi_mass_max_t>()}},
                                                                        {}};
#endif
}

void lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_Lambda_mass_t>(arguments, 0, context);
  Allen::memset_async<dev_histogram_LambdaPi_mass_t>(arguments, 0, context);
}

__device__ bool lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::select(
  const Parameters& parameters,
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
  // let's require same charge as proton as there should always be at least one positive (negative) track in
  // a (anti-) charm decay. Decays from b should be covered by the generic lines.
  const bool track_and_proton_are_same_sign =
    c0_is_proton ? companion_state.charge() == c0_state.charge() : companion_state.charge() == c1_state.charge();
  return mL < parameters.L_M_max && companion_state.pt() > parameters.t_PT_min && track_and_proton_are_same_sign &&
         Lt.doca12() < parameters.L_t_DOCA_max && Lt.m12(Allen::mL, Allen::mPi) < parameters.M_max &&
         vertex.pt() > parameters.PT_min && L_vx.z() - vertex.z() > parameters.LVDZ_min &&
         Lt.fd() > parameters.BPVFD_min && parameters.VZ_min < vertex.z() && vertex.z() < parameters.VZ_max &&
         Lt.dz() > parameters.BPVVDZ_min && Lt.dira() > parameters.BPVDIRA_min;
}

__device__ void lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::fill_tuples(
  const Parameters& parameters,
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
    // tunable up to 16, should be significantly smaller than pi_MIPCHI2. best to tune them together pi up to 42
    parameters.t_MIPCHI2[index] = companion->ip_chi2();
    parameters.t_MIP[index] = companion->ip();
    // globally tunable
    parameters.t_CHI2NDF[index] = companion->chi2() / companion->ndof();
    parameters.t_Q[index] = companion_state.charge();

    // copy paste from Lambda2PPiLine
    const auto L_vx = Lambda->vertex();
    // Proton is always the child with larger momentum
    const auto c0 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(0)),
               c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(Lambda->child(1));
    const auto proton = c0->state().p() > c1->state().p() ? c0 : c1;
    const auto pion = c0->state().p() > c1->state().p() ? c1 : c0;
    const auto proton_state = proton->state(), pion_state = pion->state();

    // tunable if needed be down to 1135 MeV
    parameters.L_M[index] =
      c0->state().p() > c1->state().p() ? Lambda->m12(Allen::mP, Allen::mPi) : Lambda->m12(Allen::mPi, Allen::mP);
    parameters.p_P[index] = proton_state.p();
    parameters.p_PT[index] = proton_state.pt();
    // tunable up to 16, should be significantly smaller than pi_MIPCHI2. best to tune them together pi up to 42
    parameters.p_MIPCHI2[index] = proton->ip_chi2();
    parameters.p_MIP[index] = proton->ip();
    // globally tunable
    parameters.p_CHI2NDF[index] = proton->chi2() / proton->ndof();
    parameters.p_Q[index] = proton_state.charge();
    parameters.pi_P[index] = pion_state.p();
    // This is what makes the Lambda line orthogonal to the TrackMVA lines. Tunable (if really needed) to 200 MeV.
    parameters.pi_PT[index] = pion_state.pt();
    // tunable, should be significantly larger than p_MIPCHI2. best to tune them together
    parameters.pi_MIPCHI2[index] = pion->ip_chi2();
    parameters.pi_MIP[index] = pion->ip();
    parameters.pi_CHI2NDF[index] = pion->chi2() / pion->ndof();
    parameters.pi_Q[index] = pion_state.charge();
    // tunable down to 8
    parameters.L_VCHI2[index] = L_vx.chi2();
    parameters.L_VZ[index] = L_vx.z();
    // better not go tighter as we don't have a full blown track propagation and would loose some of the Lambdas where p
    // and pi only leave hits in the most downstream Velo modules
    parameters.p_pi_DOCA[index] = Lambda->doca12();
    parameters.L_PT[index] = L_vx.pt();
    parameters.L_BPVVDCHI2[index] = Lambda->fdchi2();
    // tunable up to 40 mm
    parameters.L_BPVVDZ[index] = Lambda->dz();
    // tunable up to 3.2 mm
    parameters.L_BPVVDRHO[index] = Lambda->drho();
    // tunable up to 0.9998
    parameters.L_BPVDIRA[index] = Lambda->dira();
  }
}

__device__ void lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::monitor(
  const Parameters& parameters,
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
    const unsigned int L_bin = static_cast<unsigned int>(
      (mL - parameters.histogram_Lambda_mass_min) * parameters.histogram_Lambda_mass_nbins /
      (parameters.histogram_Lambda_mass_max - parameters.histogram_Lambda_mass_min));
    atomicAdd(&parameters.dev_histogram_Lambda_mass[L_bin], 1);
    const unsigned int Lpi_bin = static_cast<unsigned int>(
      (mLpi - parameters.histogram_LambdaPi_mass_min) * parameters.histogram_LambdaPi_mass_nbins /
      (parameters.histogram_LambdaPi_mass_max - parameters.histogram_LambdaPi_mass_min));
    atomicAdd(&parameters.dev_histogram_LambdaPi_mass[Lpi_bin], 1);
  }
}

void lambda_ll_detached_track_line::lambda_ll_detached_track_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {get<dev_histogram_Lambda_mass_t>(arguments),
                            histogram_Lambda_mass,
                            property<histogram_Lambda_mass_min_t>(),
                            property<histogram_Lambda_mass_max_t>()},
                std::tuple {get<dev_histogram_LambdaPi_mass_t>(arguments),
                            histogram_LambdaPi_mass,
                            property<histogram_LambdaPi_mass_min_t>(),
                            property<histogram_LambdaPi_mass_max_t>()}});
#endif
}
