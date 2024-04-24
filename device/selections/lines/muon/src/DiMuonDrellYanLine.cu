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
#include "DiMuonDrellYanLine.cuh"

INSTANTIATE_LINE(di_muon_drell_yan_line::di_muon_drell_yan_line_t, di_muon_drell_yan_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
di_muon_drell_yan_line::di_muon_drell_yan_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto particle = event_tracks.particle(i);
  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  const auto chi2corr1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const auto chi2corr2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk2->get_index()];

  return std::forward_as_tuple(particle, max(chi2corr1, chi2corr2));
}

__device__ bool di_muon_drell_yan_line::di_muon_drell_yan_line_t::select(
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto& particle = std::get<0>(input);
  const auto& maxchi2muon = std::get<1>(input);

  const bool opposite_sign = particle.charge() == 0;
  if (opposite_sign != parameters.OppositeSign) return false;

  const auto& vertex = particle.vertex();

  if (vertex.chi2() < 0) {
    return false; // this should never happen.
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  const bool decision = particle.is_dimuon() && maxchi2muon < parameters.maxChi2Muon &&
                        vertex.chi2() <= parameters.maxVertexChi2 && particle.doca12() <= parameters.maxDoca &&
                        trk1->state().pt() >= parameters.minTrackPt && trk1->state().p() >= parameters.minTrackP &&
                        trk1->state().eta() <= parameters.maxTrackEta && trk2->state().pt() >= parameters.minTrackPt &&
                        trk2->state().p() >= parameters.minTrackP && trk2->state().eta() <= parameters.maxTrackEta &&
                        particle.mdimu() >= parameters.minMass && particle.mdimu() <= parameters.maxMass &&
                        vertex.z() >= parameters.minZ;

  return decision;
}

__device__ void di_muon_drell_yan_line::di_muon_drell_yan_line_t::monitor(
  const Parameters&,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto& vertex = std::get<0>(input);
    accumulators.histogram_Z_mass.increment(vertex.mdimu());
  }
}

__device__ void di_muon_drell_yan_line::di_muon_drell_yan_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& vertex = std::get<0>(input);
    const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
    const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

    const auto m = vertex.mdimu();
    parameters.mass[index] = m;
    parameters.transverse_momentum[index] = std::min(trk1->state().pt(), trk2->state().pt());
  }
}
