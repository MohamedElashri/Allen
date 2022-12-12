/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DiMuonNoIPLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(di_muon_no_ip_line::di_muon_no_ip_line_t, di_muon_no_ip_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle>
di_muon_no_ip_line::di_muon_no_ip_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);

  return std::forward_as_tuple(vertex);
}

__device__ bool di_muon_no_ip_line::di_muon_no_ip_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const bool same_sign = vertex.charge() != 0;
  return vertex.is_dimuon() && (same_sign == parameters.ss_on) &&
         track1->state().chi2() / track1->state().ndof() <= parameters.maxTrChi2 &&
         track2->state().chi2() / track2->state().ndof() <= parameters.maxTrChi2 && track1->state().chi2() > 0 &&
         track2->state().chi2() > 0 && vertex.doca12() <= parameters.maxDoca &&
         track1->state().pt() * track2->state().pt() >= parameters.minTrackPtPROD &&
         track1->state().p() >= parameters.minTrackP && track2->state().p() >= parameters.minTrackP &&
         vertex.vertex().chi2() > 0 && vertex.vertex().chi2() <= parameters.maxVertexChi2 &&
         vertex.vertex().pt() > parameters.minPt && vertex.vertex().z() >= parameters.minZ;
}

__device__ void di_muon_no_ip_line::di_muon_no_ip_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool)
{
  const auto vertex = std::get<0>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const bool same_sign =
    !((track1->state().qop() < 0 && track2->state().qop() > 0) ||
      (track1->state().qop() > 0 && track2->state().qop() < 0));

  if (vertex.is_dimuon()) {
    parameters.dev_trk1Chi2[index] = track1->state().chi2() / track1->state().ndof();
    parameters.dev_trk2Chi2[index] = track2->state().chi2() / track2->state().ndof();
    parameters.dev_doca[index] = vertex.doca12();
    parameters.dev_trk1pt[index] = track1->state().pt();
    parameters.dev_trk2pt[index] = track2->state().pt();
    parameters.dev_p1[index] = track1->state().p();
    parameters.dev_p2[index] = track2->state().p();
    parameters.dev_vChi2[index] = vertex.vertex().chi2();
    parameters.dev_is_dimuon[index] = vertex.is_dimuon();
    parameters.dev_same_sign[index] = same_sign;
    parameters.dev_same_sign_on[index] = parameters.ss_on;
    parameters.dev_pt[index] = vertex.vertex().pt();
    parameters.dev_eventNum[index] = -1;
  }
}
