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
#include "DiMuonMassLine.cuh"

INSTANTIATE_LINE(di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>
di_muon_mass_line::di_muon_mass_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto particle = event_tracks.particle(i);

  return std::forward_as_tuple(particle, event_number);
}

__device__ bool di_muon_mass_line::di_muon_mass_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto vertex = std::get<0>(input);
  const auto event_number = std::get<1>(input);
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
    muonid_bool = max(chi2corr1, chi2corr2) < properties.maxChi2Muon;
  }
  const bool opposite_sign = vertex.charge() == 0;

  bool dec = muonid_bool && vertex.is_dimuon() && opposite_sign == properties.oppositeSign &&
             vertex.minipchi2() >= properties.minIPChi2 && vertex.doca12() <= properties.maxDoca &&
             vertex.mdimu() >= properties.minMass && vertex.minpt() >= properties.minHighMassTrackPt &&
             vertex.minp() >= properties.minHighMassTrackP && vertex.vertex().chi2() > 0 &&
             vertex.vertex().chi2() < properties.maxVertexChi2 && vertex.vertex().z() >= properties.minZ &&
             vertex.pv().position.z >= properties.minZ;
  if (dec && properties.vetoSharedHits) {
    using segment = Allen::Views::Physics::Track::segment;
    const auto* muon_segment1 = trk1->track().track_segment_ptr<segment::muon>();
    const auto* muon_segment2 = trk2->track().track_segment_ptr<segment::muon>();
    for (unsigned i = 0; i < muon_segment1->number_of_ids(); i++) {
      for (unsigned j = 0; j < muon_segment2->number_of_ids(); j++) {
        dec &= muon_segment1->hit(i).id() != muon_segment2->hit(j).id();
      }
    }
  }
  return dec;
}

__device__ void di_muon_mass_line::di_muon_mass_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    properties.histogram_Jpsi_mass.increment(particle.m());
  }
}

__device__ bool di_muon_mass_line::di_muon_mass_line_t::fill_tuples(
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
