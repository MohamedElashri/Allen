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
#include "DiMuonMassAlignmentLine.cuh"

INSTANTIATE_LINE(di_muon_mass_alignment_line::di_muon_mass_alignment_line_t, di_muon_mass_alignment_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
di_muon_mass_alignment_line::di_muon_mass_alignment_line_t::get_input(
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

__device__ bool di_muon_mass_alignment_line::di_muon_mass_alignment_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto vertex = std::get<0>(input);
  const auto maxchi2muon = std::get<1>(input);
  if (vertex.charge() != parameters.DiMuonCharge) return false;

  return maxchi2muon < parameters.maxChi2Muon && vertex.is_dimuon() && vertex.minip() >= parameters.minIP &&
         vertex.doca12() <= parameters.maxDoca && vertex.mdimu() >= parameters.minMass &&
         vertex.mdimu() <= parameters.maxMass && vertex.minpt() >= parameters.minHighMassTrackPt &&
         vertex.vertex().pt() > parameters.minComboPt && vertex.dira() > parameters.minDira &&
         vertex.minp() >= parameters.minHighMassTrackP && vertex.vertex().chi2() > 0 &&
         vertex.fdchi2() > parameters.minFdChi2 && vertex.eta() > parameters.minEta &&
         vertex.eta() < parameters.maxEta && vertex.vertex().chi2() < parameters.maxVertexChi2 &&
         vertex.vertex().z() >= parameters.minZ && vertex.has_pv() && vertex.pv().position.z >= parameters.minZ;
}
