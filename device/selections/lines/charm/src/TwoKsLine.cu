/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TwoKsLine.cuh"

INSTANTIATE_LINE(two_ks_line::two_ks_line_t, two_ks_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned>
two_ks_line::two_ks_line_t::get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
{
  const auto particles = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].particle_container(event_number));
  const auto particle = particles.particle(i);
  return std::forward_as_tuple(particle, event_number, i);
}

__device__ bool two_ks_line::two_ks_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned> input)
{
  // Unpack the tuple.
  const auto vertex1 = std::get<0>(input);
  const auto& event_number = std::get<1>(input);
  const auto& vertex1_id = std::get<2>(input);

  const auto particles = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].particle_container(event_number));
  unsigned n_svs = particles.size();
  for (unsigned i = threadIdx.y + vertex1_id + 1; i < n_svs; i += blockDim.y) {
    const auto vertex2 = particles.particle(i);

    // Return false if the vertices have a common track.
    // Make this selection first as it is will initially reject the
    // largest amount of combinations.
    if (
      vertex1.substructure(0) == vertex2.substructure(0) || vertex1.substructure(0) == vertex2.substructure(1) ||
      vertex1.substructure(1) == vertex2.substructure(0) || vertex1.substructure(1) == vertex2.substructure(1)) {
      continue;
    }

    // Return false if vertex fit failed for either vertex.
    if (vertex1.vertex().chi2() < 0) {
      return false;
    }

    if (vertex2.vertex().chi2() < 0) {
      continue;
    }

    // Need all four individual tracks for these cuts.
    const auto v1track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex1.substructure(0));
    const auto v1track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex1.substructure(1));
    const auto v2track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex2.substructure(0));
    const auto v2track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex2.substructure(1));
    const auto cos1 =
      (v1track1->px() * v1track2->px() + v1track1->py() * v1track2->py() + v1track1->pz() * v1track2->pz()) /
      (v1track1->p() * v1track2->p());
    const auto cos2 =
      (v2track1->px() * v2track2->px() + v2track1->py() * v2track2->py() + v2track1->pz() * v2track2->pz()) /
      (v2track1->p() * v2track2->p());
    // This decision is split into multiple lines because evaluating in all at
    // once results in a heavy register load. This can cause crashes depending
    // on the number of threads in the block.
    bool decision = vertex1.vertex().chi2() < parameters.maxVertexChi2 && vertex1.eta() > parameters.minEta_Ks &&
                    vertex1.eta() < parameters.maxEta_Ks && vertex1.minipchi2() > parameters.minTrackIPChi2_Ks;
    decision &= vertex1.mdipi() > parameters.minM_Ks && vertex1.mdipi() < parameters.maxM_Ks &&
                vertex1.pt() > parameters.minComboPt_Ks && cos1 > parameters.minCosOpening &&
                vertex1.dira() > parameters.minCosDira && vertex1.minp() > parameters.minTrackP_piKs;
    decision &= v1track1->ip() * v1track2->ip() / vertex1.ip() > parameters.min_combip &&
                vertex1.minpt() > parameters.minTrackPt_piKs;
    decision &= vertex2.vertex().chi2() < parameters.maxVertexChi2 && vertex2.eta() > parameters.minEta_Ks &&
                vertex2.eta() < parameters.maxEta_Ks && vertex2.minipchi2() > parameters.minTrackIPChi2_Ks;
    decision &= vertex2.mdipi() > parameters.minM_Ks && vertex2.mdipi() < parameters.maxM_Ks &&
                vertex2.pt() > parameters.minComboPt_Ks && cos2 > parameters.minCosOpening &&
                vertex2.dira() > parameters.minCosDira && vertex2.minp() > parameters.minTrackP_piKs;
    decision &= v2track1->ip() * v2track2->ip() / vertex2.ip() > parameters.min_combip &&
                vertex2.minpt() > parameters.minTrackPt_piKs;

    if (decision) {
      return decision;
    }
  }

  return false;
}
