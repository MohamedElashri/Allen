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
  const auto muonidnn1 = parameters.dev_muonid_nn[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const auto muonidnn2 = parameters.dev_muonid_nn[parameters.dev_track_offsets[event_number] + track2->get_index()];
  float min_nn = min(muonidnn1, muonidnn2);
  return std::forward_as_tuple(vertex, min_nn);
}
__device__ bool di_muon_no_ip_line::di_muon_no_ip_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto vertex = std::get<0>(input);
  const auto min_nn = std::get<1>(input);

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const bool same_sign = vertex.charge() != 0;
  bool dec = min_nn > properties.minNN && vertex.is_dimuon() && (same_sign == properties.ss_on) &&
             track1->state().chi2() / track1->state().ndof() <= properties.maxTrChi2 &&
             track2->state().chi2() / track2->state().ndof() <= properties.maxTrChi2 && track1->state().chi2() > 0 &&
             track2->state().chi2() > 0 && vertex.doca12() <= properties.maxDoca &&
             track1->state().pt() * track2->state().pt() >= properties.minTrackPtPROD &&
             track1->state().p() >= properties.minTrackP && track2->state().p() >= properties.minTrackP &&
             vertex.vertex().chi2() > 0 && vertex.vertex().chi2() <= properties.maxVertexChi2 &&
             vertex.vertex().pt() > properties.minPt && vertex.vertex().z() >= properties.minZ;
  if (dec) {
    using segment = Allen::Views::Physics::Track::segment;
    const auto* muon_segment1 = track1->track().track_segment_ptr<segment::muon>();
    const auto* muon_segment2 = track2->track().track_segment_ptr<segment::muon>();
    for (unsigned i = 0; i < muon_segment1->number_of_ids(); i++) {
      for (unsigned j = 0; j < muon_segment2->number_of_ids(); j++) {
        dec &= muon_segment1->hit(i).id() != muon_segment2->hit(j).id();
      }
    }
  }
  return dec;
}

__device__ void di_muon_no_ip_line::di_muon_no_ip_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto vertex = std::get<0>(input);
    const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
    const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
    if (track1->ip_chi2() < 6 && track2->ip_chi2() < 6) {
      float q = sqrtf(vertex.mdimu() * vertex.mdimu() - 4 * Allen::mMu * Allen::mMu);
      properties.histogram_prompt_q.increment(q);
    }
  }
}
__device__ bool di_muon_no_ip_line::di_muon_no_ip_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    parameters.ipchi2[index] = particle.minipchi2();
    parameters.pt[index] = particle.minpt();
    parameters.dev_muon_nn[index] = std::get<1>(input);
  }
  return sel;
}