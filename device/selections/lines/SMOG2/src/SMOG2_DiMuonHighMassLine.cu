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

void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::init()
{
  Line<SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t, SMOG2_dimuon_highmass_line::Parameters>::init();

  m_histogram_smogdimuon_mass.axis().nBins = property<histogram_smogdimuon_mass_nbins_t>();
  m_histogram_smogdimuon_mass.axis().minValue = property<histogram_smogdimuon_mass_min_t>();
  m_histogram_smogdimuon_mass.axis().maxValue = property<histogram_smogdimuon_mass_max_t>();

  m_histogram_smogdimuon_svz.axis().nBins = property<histogram_smogdimuon_svz_nbins_t>();
  m_histogram_smogdimuon_svz.axis().minValue = property<histogram_smogdimuon_svz_min_t>();
  m_histogram_smogdimuon_svz.axis().maxValue = property<histogram_smogdimuon_svz_max_t>();
}

__device__ bool SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::select(
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto& vtx = std::get<0>(input);
  if (vtx.vertex().chi2() < 0) {
    return false;
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(1));
  const auto maxchi2muon = std::get<1>(input);

  bool decision = maxchi2muon < parameters.maxChi2Corr && vtx.vertex().z() < parameters.maxZ && vtx.is_dimuon() &&
                  vtx.doca12() < parameters.maxDoca && trk1->chi2() / trk1->ndof() < parameters.maxTrackChi2Ndf &&
                  trk2->chi2() / trk2->ndof() < parameters.maxTrackChi2Ndf && vtx.mdimu() >= parameters.minMass &&
                  vtx.minpt() >= parameters.minTrackPt && vtx.minp() >= parameters.minTrackP &&
                  vtx.vertex().chi2() < parameters.maxVertexChi2 && vtx.vertex().z() >= parameters.minZ &&
                  vtx.charge() == parameters.CombCharge;
  if (vtx.has_pv()) decision = decision && vtx.pv().position.z < parameters.maxZ;

  return decision;
}

__device__ void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::monitor(
  const Parameters& parameters,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned index,
  bool sel)
{
  const auto dimuon = std::get<0>(input);
  if (sel) {
    parameters.smogdimuon_masses[index] = dimuon.mdimu();
    parameters.smogdimuon_svz[index] = dimuon.vertex().z();

    accumulators.histogram_smogdimuon_mass.increment(dimuon.mdimu());
    accumulators.histogram_smogdimuon_svz.increment(dimuon.vertex().z());
  }
}
