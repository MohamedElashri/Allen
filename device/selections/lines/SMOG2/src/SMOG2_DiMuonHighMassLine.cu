/*****************************************************************************\
 * (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "SMOG2_DiMuonHighMassLine.cuh"

INSTANTIATE_LINE(SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t, SMOG2_dimuon_highmass_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::get_input(
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

__device__ bool SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto& vtx = std::get<0>(input);
  if (vtx.vertex().chi2() < 0) {
    return false;
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(1));
  const auto maxchi2muon = std::get<1>(input);

  bool decision = maxchi2muon < properties.maxChi2Corr && vtx.vertex().z() < properties.maxZ && vtx.is_dimuon() &&
                  vtx.doca12() < properties.maxDoca && trk1->chi2() / trk1->ndof() < properties.maxTrackChi2Ndf &&
                  trk2->chi2() / trk2->ndof() < properties.maxTrackChi2Ndf && vtx.mdimu() >= properties.minMass &&
                  vtx.minpt() >= properties.minTrackPt && vtx.minp() >= properties.minTrackP &&
                  vtx.vertex().chi2() < properties.maxVertexChi2 && vtx.vertex().z() >= properties.minZ &&
                  vtx.charge() == properties.HighMassCombCharge && vtx.has_pv() &&
                  vtx.pv().position.z < properties.maxZ;

  return decision;
}

__device__ void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto dimuon = std::get<0>(input);
    properties.histogram_smogdimuon_mass.increment(dimuon.mdimu());
    properties.histogram_smogdimuon_svz.increment(dimuon.vertex().z());
    properties.histogram_smogdimuon_pvz.increment(dimuon.pv().position.z);
    properties.histogram_smogdimuon_pt.increment(dimuon.vertex().pt());
  }
}

__device__ bool SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto dimuon = std::get<0>(input);

    parameters.mass[index] = dimuon.mdimu();
    parameters.svz[index] = dimuon.vertex().z();
    parameters.pvz[index] = dimuon.pv().position.z;
    parameters.pt[index] = dimuon.vertex().pt();
    parameters.maxchi2corr[index] = std::get<1>(input);
  }
  return sel;
}
