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
#include "DiMuonNoIPLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"
#include <array>
#include <unistd.h>
#include "BinarySearch.cuh"

INSTANTIATE_LINE(di_muon_no_ip_line::di_muon_no_ip_line_t, di_muon_no_ip_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
di_muon_no_ip_line::di_muon_no_ip_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const auto chi2corr1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const auto chi2corr2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + track2->get_index()];

  return std::forward_as_tuple(vertex, max(chi2corr1, chi2corr2));
}

__device__ bool di_muon_no_ip_line::di_muon_no_ip_line_t::select(
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto vertex = std::get<0>(input);
  const auto maxchi2muon = std::get<1>(input);

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const bool same_sign = vertex.charge() != 0;

  return maxchi2muon < parameters.maxChi2Muon && vertex.is_dimuon() && (same_sign == parameters.ss_on) &&
         track1->state().chi2() / track1->state().ndof() <= parameters.maxTrChi2 &&
         track2->state().chi2() / track2->state().ndof() <= parameters.maxTrChi2 && track1->state().chi2() > 0 &&
         track2->state().chi2() > 0 && vertex.doca12() <= parameters.maxDoca &&
         track1->state().pt() * track2->state().pt() >= parameters.minTrackPtPROD &&
         track1->state().p() >= parameters.minTrackP && track2->state().p() >= parameters.minTrackP &&
         vertex.vertex().chi2() > 0 && vertex.vertex().chi2() <= parameters.maxVertexChi2 &&
         vertex.vertex().pt() > parameters.minPt && vertex.vertex().z() >= parameters.minZ;
}

__device__ void di_muon_no_ip_line::di_muon_no_ip_line_t::monitor(
  const Parameters&,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto vertex = std::get<0>(input);
    const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
    const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
    if (track1->ip_chi2() < 6 && track2->ip_chi2() < 6) {
      float q = sqrtf(vertex.m() * vertex.m() - 4 * Allen::mMu * Allen::mMu);
      accumulators.histogram_prompt_q.increment(q);
    }
  }
}
