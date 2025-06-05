/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TauToPhiMuLine.cuh"

INSTANTIATE_LINE(tautophimu_line::tautophimu_line_t, tautophimu_line::Parameters)

// Get the invariant mass of the phi and one additional track
__device__ float tautophimu_line::tautophimu_line_t::m(
  const Allen::Views::Physics::CompositeParticle* phi,
  const Allen::Views::Physics::BasicParticle* track,
  const float m1,
  const float m2)
{
  const auto phi_vertex = phi->vertex();
  const auto track_state = track->state();
  const float E1 = sqrtf(
    phi_vertex.px() * phi_vertex.px() + phi_vertex.py() * phi_vertex.py() + phi_vertex.pz() * phi_vertex.pz() +
    m1 * m1);
  const float E2 = sqrtf(
    track_state.px() * track_state.px() + track_state.py() * track_state.py() + track_state.pz() * track_state.pz() +
    m2 * m2);
  return sqrtf(
    m1 * m1 + m2 * m2 +
    2.f * (E1 * E2 - (phi_vertex.px() * track_state.px() + phi_vertex.py() * track_state.py() +
                      phi_vertex.pz() * track_state.pz())));
}

// Get the absolute 3-momentum of the phi and one additional track
__device__ float tautophimu_line::tautophimu_line_t::p(
  const Allen::Views::Physics::CompositeParticle* phi,
  const Allen::Views::Physics::BasicParticle* track)
{
  const auto phi_vertex = phi->vertex();
  const auto track_state = track->state();
  return sqrtf(
    (phi_vertex.px() + track_state.px()) * (phi_vertex.px() + track_state.px()) +
    (phi_vertex.py() + track_state.py()) * (phi_vertex.py() + track_state.py()) +
    (phi_vertex.pz() + track_state.pz()) * (phi_vertex.pz() + track_state.pz()));
}

// Get the transverse momentum of the phi and one additional track
__device__ float tautophimu_line::tautophimu_line_t::pt(
  const Allen::Views::Physics::CompositeParticle* phi,
  const Allen::Views::Physics::BasicParticle* track)
{
  const auto phi_vertex = phi->vertex();
  const auto track_state = track->state();
  return sqrtf(
    (phi_vertex.px() + track_state.px()) * (phi_vertex.px() + track_state.px()) +
    (phi_vertex.py() + track_state.py()) * (phi_vertex.py() + track_state.py()));
}

// Get the lifetime of a pair of vertices
__device__ float tautophimu_line::tautophimu_line_t::ctau(
  const Allen::Views::Physics::CompositeParticle* phi,
  const Allen::Views::Physics::BasicParticle* track)
{
  // This function calculates lifetime as ctau = m*L/p (mm)
  const auto mkk = phi->m12(Allen::mK, Allen::mK); // KK
  auto L = phi->fd();
  auto M = m(phi, track, mkk, Allen::mMu);
  auto P = p(phi, track);
  return M * L / P;
}

__device__ bool tautophimu_line::tautophimu_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const auto phi = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));
  const auto third_track = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  const auto phi_K1 = static_cast<const Allen::Views::Physics::BasicParticle*>(phi->child(0));
  const auto phi_K2 = static_cast<const Allen::Views::Physics::BasicParticle*>(phi->child(1));

  const auto phi_vertex = phi->vertex();
  const auto third_track_state = third_track->state();

  const auto mkk = phi->m12(Allen::mK, Allen::mK); // KK

  // Make sure the vertex fit succeeded
  if (phi_vertex.chi2() < 0) {
    return false;
  }

  // Make sure the phi(1020) has 0 electric charge
  if (phi_K1->state().charge() + phi_K2->state().charge() != 0) {
    return false;
  }

  const bool decision =
    phi->minp() > properties.minTrackP && phi->minpt() > properties.minTrackPt &&
    phi->minipchi2() > properties.minTrackIPChi2 && phi->minip() > properties.minTrackIP &&
    phi->eta() > properties.minTrackEta && phi->eta() < properties.maxTrackEta &&
    phi_vertex.pt() > properties.minPhiPt && phi_vertex.chi2() < properties.maxPhiVertexChi2 &&
    phi->doca12() < properties.maxPhiDOCA && phi->fdchi2() > properties.minPhiFDChi2 &&
    fabsf(mkk - Allen::mPhi) < properties.PhiMassWindow &&
    Allen::Views::Physics::state_doca(phi->get_state(), third_track->state().operator MiniState()) <
      properties.maxDOCA &&
    pt(phi, third_track) > properties.minSVpt && ctau(phi, third_track) > properties.minctau &&
    ctau(phi, third_track) < properties.maxctau && third_track_state.p() > properties.minThirdTrackP &&
    third_track_state.pt() > properties.minThirdTrackPt && third_track->ip_chi2() > properties.minThirdTrackIPChi2 &&
    third_track_state.eta() > properties.minThirdTrackEta && third_track_state.eta() < properties.maxThirdTrackEta &&
    third_track->is_muon() && m(phi, third_track, mkk, Allen::mMu) > properties.minInvMass &&
    m(phi, third_track, mkk, Allen::mMu) < properties.maxInvMass && phi_vertex.z() >= properties.minZ &&
    phi->pv().position.z >= properties.minZ;
  return decision;
}

__device__ void tautophimu_line::tautophimu_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto phi = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));

    const float pt = phi->vertex().pt();
    const auto mkk = phi->m12(Allen::mK, Allen::mK); // KK

    properties.histogram_phi_pt.increment(pt);
    properties.histogram_phi_m.increment(mkk);
  }
}

__device__ bool tautophimu_line::tautophimu_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& particle = std::get<0>(input);
    const auto phi = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));
    const auto third_track = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));
    const auto mkk = phi->m12(Allen::mK, Allen::mK); // KK

    const auto phi_K1 = static_cast<const Allen::Views::Physics::BasicParticle*>(phi->child(0));
    const auto phi_K2 = static_cast<const Allen::Views::Physics::BasicParticle*>(phi->child(1));

    parameters.min_p[index] = phi->minp();
    parameters.min_pt[index] = phi->minpt();
    parameters.min_ip[index] = phi->minip();
    parameters.min_ipchi2[index] = phi->minipchi2();
    parameters.phi_eta[index] = phi->eta();
    parameters.phi_pt[index] = phi->vertex().pt();
    parameters.phi_chi2[index] = phi->vertex().chi2();
    parameters.phi_doca[index] = phi->doca12();
    parameters.phi_mass[index] = mkk;
    parameters.phi_fdchi2[index] = phi->fdchi2();
    parameters.phi_fd[index] = phi->fd();
    parameters.doca_phi_track[index] =
      Allen::Views::Physics::state_doca(phi->get_state(), third_track->state().operator MiniState());
    parameters.tau_pt[index] = pt(phi, third_track);
    parameters.ctau[index] = ctau(phi, third_track);
    parameters.mu_p[index] = third_track->state().p();
    parameters.mu_pt[index] = third_track->state().pt();
    parameters.mu_ip_chi2[index] = third_track->ip_chi2();
    parameters.mu_eta[index] = third_track->state().eta();
    parameters.mu_ismuon[index] = third_track->is_muon();
    parameters.tau_mass[index] = m(phi, third_track, mkk, Allen::mMu);
    parameters.phi_vertex_z[index] = phi->vertex().z();
    parameters.pv_z[index] = phi->pv().position.z;
    parameters.phi_drho[index] = phi->drho();
    parameters.phi_dz[index] = phi->dz();
    parameters.phi_dira[index] = phi->dira();
    parameters.K1_ismuon[index] = phi_K1->is_muon();
    parameters.K2_ismuon[index] = phi_K2->is_muon();
  }
  return sel;
}