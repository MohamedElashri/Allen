/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TwoTrackMVALine.cuh"

INSTANTIATE_LINE(two_track_mva_line::two_track_mva_line_t, two_track_mva_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
two_track_mva_line::two_track_mva_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto particles = static_cast<const Allen::Views::Physics::CompositeParticles>(
    parameters.dev_particle_container[0].container(event_number));
  const unsigned sv_index = i + particles.offset();
  const auto particle = particles.particle(i);
  return std::forward_as_tuple(particle, parameters.dev_two_track_mva_evaluation[sv_index]);
}

__device__ bool two_track_mva_line::two_track_mva_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto& vertex = std::get<0>(input);
  const auto& response = std::get<1>(input);
  const auto a = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto b = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  bool presel =
    (vertex.minpt() > properties.minPt && vertex.eta() > properties.minEta && vertex.eta() < properties.maxEta &&
     vertex.mcor() > properties.minMcor && vertex.vertex().pt() > properties.minSVpt &&
     vertex.vertex().chi2() < properties.maxSVchi2 && vertex.doca12() < properties.maxDOCA &&
     vertex.vertex().z() >= properties.minZ && vertex.minipchi2() > properties.minipchi2);
  if (vertex.has_pv()) presel = presel && vertex.pv().position.z >= properties.minZ;

  return presel && response > properties.minMVA && a->track().ghost_probability() < properties.maxGhostProb &&
         b->track().ghost_probability() < properties.maxGhostProb;
}

__device__ void two_track_mva_line::two_track_mva_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto p0 = static_cast<const Allen::Views::Physics::BasicParticle*>(std::get<0>(input).child(0));
    const auto p1 = static_cast<const Allen::Views::Physics::BasicParticle*>(std::get<0>(input).child(1));
    properties.histogram_p0_ghost_prob.increment(p0->track().ghost_probability());
    properties.histogram_p1_ghost_prob.increment(p1->track().ghost_probability());
    properties.histogram_p0_ip_x.increment(p0->ip_x());
    properties.histogram_p1_ip_x.increment(p1->ip_x());
    properties.histogram_p0_ip_y.increment(p0->ip_y());
    properties.histogram_p1_ip_y.increment(p1->ip_y());
    properties.histogram_d0_mass.increment(particle.m12(Allen::mK, Allen::mPi));
  }
}

__device__ bool two_track_mva_line::two_track_mva_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto a = static_cast<const Allen::Views::Physics::BasicParticle*>(std::get<0>(input).child(0));
    const auto b = static_cast<const Allen::Views::Physics::BasicParticle*>(std::get<0>(input).child(1));
    parameters.mva[index] = std::get<1>(input);
    parameters.maxChildGhostProb[index] = std::max(a->track().ghost_probability(), b->track().ghost_probability());
  }
  return sel;
}
