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

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
SMOG2_displaced_di_muon_line::SMOG2_displaced_di_muon_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const unsigned idx1_with_offset = parameters.dev_track_offsets[event_number] + track1->get_index();
  const unsigned idx2_with_offset = parameters.dev_track_offsets[event_number] + track2->get_index();
  const auto chi2corr1 = parameters.dev_chi2muon[idx1_with_offset];
  const auto chi2corr2 = parameters.dev_chi2muon[idx2_with_offset];

  return std::forward_as_tuple(vertex, max(chi2corr1, chi2corr2));
}

__device__ bool SMOG2_displaced_di_muon_line::SMOG2_displaced_di_muon_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto vertex = std::get<0>(input);
  const auto maxchi2muon = std::get<1>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.mdimu() < properties.mass) return false;
  if (!vertex.has_pv()) return false;
  if (!(vertex.pv().position.z < properties.maxPVZ && vertex.pv().position.z > properties.minPVZ)) return false;

  bool decision = maxchi2muon < properties.maxChi2CorrMuon && vertex.vertex().chi2() > 0 &&
                  vertex.vertex().pt() > properties.minComboPt && vertex.vertex().chi2() < properties.maxVertexChi2 &&
                  vertex.minpt() > properties.minDispTrackPt && vertex.vertex().z() >= properties.minZ &&
                  vertex.ip() < properties.maxIP && vertex.fdchi2() > properties.minFDCHI2;
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
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto vertex = std::get<0>(input);
    properties.histogram_displaced_dimuon_mass.increment(vertex.mdimu());
  }
}
