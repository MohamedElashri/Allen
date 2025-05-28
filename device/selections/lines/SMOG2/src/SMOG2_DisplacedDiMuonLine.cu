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
#include "SMOG2_DisplacedDiMuonLine.cuh"

INSTANTIATE_LINE(SMOG2_displaced_di_muon_line::SMOG2_displaced_di_muon_line_t, SMOG2_displaced_di_muon_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>
SMOG2_displaced_di_muon_line::SMOG2_displaced_di_muon_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);

  return std::forward_as_tuple(vertex, event_number);
}

__device__ bool SMOG2_displaced_di_muon_line::SMOG2_displaced_di_muon_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto vertex = std::get<0>(input);
  const auto event_number = std::get<1>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.mdimu() < properties.mass) return false;
  if (!vertex.has_pv()) return false;
  if (!(vertex.pv().position.z < properties.maxPVZ && vertex.pv().position.z > properties.minPVZ)) return false;

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const auto chi2corr1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const auto chi2corr2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk2->get_index()];

  const auto nn1 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const auto nn2 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk2->get_index()];
  bool muonid_bool = false;
  if (properties.useNN) {
    muonid_bool = min(nn1, nn2) > properties.minMuonNN;
  }
  else {
    muonid_bool = max(chi2corr1, chi2corr2) < properties.maxChi2CorrMuon;
  }

  bool decision = muonid_bool && vertex.vertex().chi2() > 0 && vertex.vertex().pt() > properties.minComboPt &&
                  vertex.vertex().chi2() < properties.maxVertexChi2 && vertex.minpt() > properties.minDispTrackPt &&
                  vertex.vertex().z() >= properties.minZ && vertex.ip() < properties.maxIP &&
                  vertex.fdchi2() > properties.minFDCHI2;
  if (decision) {
    using segment = Allen::Views::Physics::Track::segment;
    const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
    const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
    const auto* muon_segment1 = track1->track().track_segment_ptr<segment::muon>();
    const auto* muon_segment2 = track2->track().track_segment_ptr<segment::muon>();
    for (unsigned i = 0; i < muon_segment1->number_of_ids(); i++) {
      for (unsigned j = 0; j < muon_segment2->number_of_ids(); j++) {
        decision &= muon_segment1->hit(i).id() != muon_segment2->hit(j).id();
      }
    }
  }

  return decision;
}

__device__ void SMOG2_displaced_di_muon_line::SMOG2_displaced_di_muon_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto vertex = std::get<0>(input);
    properties.histogram_displaced_dimuon_mass.increment(vertex.mdimu());
  }
}

__device__ bool SMOG2_displaced_di_muon_line::SMOG2_displaced_di_muon_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto event_number = std::get<1>(input);
    const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
    const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

    const auto chi2corr1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk1->get_index()];
    const auto chi2corr2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk2->get_index()];

    const auto nn1 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk1->get_index()];
    const auto nn2 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk2->get_index()];
    parameters.ipchi2[index] = particle.minipchi2();
    parameters.pt[index] = particle.minpt();
    parameters.muonchi2[index] = max(chi2corr1, chi2corr2);
    parameters.muon_nn[index] = min(nn1, nn2);
  }
  return sel;
}
