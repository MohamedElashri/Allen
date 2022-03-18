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

__device__ unsigned two_track_mva_line::two_track_mva_line_t::offset(
  const Parameters& parameters,
  const unsigned event_number)
{
  const auto particles = parameters.dev_particle_container->container(event_number);
  return particles.offset();
}

__device__ unsigned two_track_mva_line::two_track_mva_line_t::input_size(
  const Parameters& parameters,
  const unsigned event_number)
{
  const auto particles = parameters.dev_particle_container->container(event_number);
  return particles.size();
}

unsigned two_track_mva_line::two_track_mva_line_t::get_decisions_size(ArgumentReferences<Parameters>& arguments)
{
  return first<typename Parameters::host_number_of_svs_t>(arguments);
}

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle&, const float>
two_track_mva_line::two_track_mva_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto particles = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const unsigned sv_index = i + particles.offset();
  const auto particle = particles.particle(i);
  return std::forward_as_tuple(particle, parameters.dev_two_track_mva_evaluation[sv_index]);
}

__device__ bool two_track_mva_line::two_track_mva_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle&, const float> input)
{
  const auto vertex = std::get<0>(input);
  const auto& response = std::get<1>(input);
  const bool presel =
    (vertex.minpt() > parameters.minPt && vertex.eta() > parameters.minEta && vertex.eta() < parameters.maxEta &&
     vertex.mcor() > parameters.minMcor && vertex.vertex().pt() > parameters.minSVpt &&
     vertex.vertex().chi2() < parameters.maxSVchi2 && vertex.doca12() < parameters.maxDOCA);
  return presel && response > parameters.minMVA;
}
