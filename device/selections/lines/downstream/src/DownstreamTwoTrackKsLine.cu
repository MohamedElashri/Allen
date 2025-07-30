/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DownstreamTwoTrackKsLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(downstream_two_track_ks_line::downstream_two_track_ks_line_t, downstream_two_track_ks_line::Parameters)

__device__ bool downstream_two_track_ks_line::downstream_two_track_ks_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const bool opposite_sign = particle.charge() == 0;

  if (opposite_sign != properties.OppositeSign) return false;
  const auto& vertex = particle.vertex();
  if (vertex.chi2() < 0) {
    return false;
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  bool decision = vertex.chi2() < properties.maxVertexChi2 && particle.eta() > properties.minEta_Ks &&
                  particle.eta() < properties.maxEta_Ks && particle.has_pv() &&
                  particle.m12(Allen::mPi, Allen::mPi) > properties.minM_Ks &&
                  particle.m12(Allen::mPi, Allen::mPi) < properties.maxM_Ks && vertex.pt() > properties.minComboPt_Ks &&
                  particle.minp() > properties.minTrackP_piKs && trk1->has_pv() && trk2->has_pv() &&
                  particle.minip() > properties.minTrackIP_piKs && particle.minpt() > properties.minTrackPt_piKs &&
                  vertex.z() >= properties.minZ_sv && particle.pv().position.z >= properties.minZ_pv;

  return decision;
}

__device__ void downstream_two_track_ks_line::downstream_two_track_ks_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto ks = std::get<0>(input);
    const float m = ks.m12(Allen::mPi, Allen::mPi);
    const float pt = ks.vertex().pt();

    properties.histogram_ks_mass.increment(m);
    properties.histogram_ks_pt.increment(pt);
  }
}

__device__ bool downstream_two_track_ks_line::downstream_two_track_ks_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  // Unpack the tuple.
  const auto ks = std::get<0>(input);

  const auto kstrk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks.child(0));
  const auto kstrk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks.child(1));
  const auto& ksstate1 = kstrk1->state();
  const auto& ksstate2 = kstrk2->state();

  if (sel) {
    parameters.dev_pt_pi1_ks[index] = ksstate1.pt();
    parameters.dev_pt_pi2_ks[index] = ksstate2.pt();
    parameters.dev_p_pi1_ks[index] = ksstate1.p();
    parameters.dev_p_pi2_ks[index] = ksstate2.p();
    parameters.dev_ipchi2_pi1_ks[index] = kstrk1->ip_chi2();
    parameters.dev_ipchi2_pi2_ks[index] = kstrk2->ip_chi2();
    parameters.dev_ip_pi1_ks[index] = kstrk1->ip();
    parameters.dev_ip_pi2_ks[index] = kstrk2->ip();

    parameters.dev_ip_ks[index] = ks.ip();
    parameters.dev_pt_ks[index] = ks.vertex().pt();
    parameters.dev_chi2vtx_ks[index] = ks.vertex().chi2();
    parameters.dev_dira_ks[index] = ks.dira();
    parameters.dev_eta_ks[index] = ks.eta();
    parameters.dev_mks[index] = ks.mdipi();

    parameters.dev_pvx[index] = ks.pv().position.x;
    parameters.dev_pvy[index] = ks.pv().position.y;
    parameters.dev_pvz[index] = ks.pv().position.z;
    parameters.dev_svx[index] = ks.vertex().x();
    parameters.dev_svy[index] = ks.vertex().y();
    parameters.dev_svz[index] = ks.vertex().z();
    parameters.dev_px_ks[index] = ks.vertex().px();
    parameters.dev_py_ks[index] = ks.vertex().py();
    parameters.dev_pz_ks[index] = ks.vertex().pz();
    parameters.dev_chi2trk_pi1_ks[index] = kstrk1->chi2() / kstrk1->ndof();
    parameters.dev_chi2trk_pi2_ks[index] = kstrk2->chi2() / kstrk2->ndof();

    parameters.dev_decision[index] = sel;
  }
  return sel;
}