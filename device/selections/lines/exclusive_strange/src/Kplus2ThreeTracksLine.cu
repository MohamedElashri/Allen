/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "Kplus2ThreeTracksLine.cuh"

INSTANTIATE_LINE(kplus_to_three_tracks_line::kplus_to_three_tracks_line_t, kplus_to_three_tracks_line::Parameters)

__device__ bool kplus_to_three_tracks_line::kplus_to_three_tracks_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const auto c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto c2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));
  const auto piplus = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(2));

  const auto c1_state = c1->state();
  const auto c2_state = c2->state();

  // Calculate c1 + c2 invariant mass
  const float e_pair = c1_state.e(properties.mass_seed_track_one * Allen::Units::MeV) +
                       c2_state.e(properties.mass_seed_track_two * Allen::Units::MeV);
  const float p2_pair = (c1_state.px() + c2_state.px()) * (c1_state.px() + c2_state.px()) +
                        (c1_state.py() + c2_state.py()) * (c1_state.py() + c2_state.py()) +
                        (c1_state.pz() + c2_state.pz()) * (c1_state.pz() + c2_state.pz());
  const float m_pair = sqrtf(e_pair * e_pair - p2_pair);

  // Calculate the combination invariant mass
  const auto piplus_state = piplus->state();
  const float p2_kplus = particle.vertex().p2();
  const float e_kplus = piplus_state.e(properties.mass_companion * Allen::Units::MeV) +
                        c1_state.e(properties.mass_seed_track_one * Allen::Units::MeV) +
                        c2_state.e(properties.mass_seed_track_two * Allen::Units::MeV);
  const float m_kplus = sqrtf(e_kplus * e_kplus - p2_kplus);

  if (properties.is_dimuon) {
    if (!c1->is_muon() || !c2->is_muon()) {
      return false;
    }
  }

  if (properties.is_dielectron) {
    if (!c1->is_electron() || !c2->is_electron()) {
      return false;
    }
  }

  const bool decision = m_pair > properties.minPairMass && m_pair < properties.maxPairMass &&
                        particle.vertex().pt() > properties.minComboPt && particle.eta() > properties.minEta &&
                        particle.eta() < properties.maxEta && particle.doca(0, 1) < properties.maxDOCA &&
                        particle.doca(0, 2) < properties.maxDOCA && particle.doca(1, 2) < properties.maxDOCA &&
                        particle.minpt() > properties.minTrackPt && particle.minip() > properties.minTrackIP &&
                        (Allen::mK - m_kplus) < properties.massWindow_min &&
                        (m_kplus - Allen::mK) < properties.massWindow_max && particle.vertex().z() > properties.minZ &&
                        particle.pv().position.z >= properties.minZ && particle.fd() > properties.minFlightDistance &&
                        c1_state.p() > properties.minTrackP && c2_state.p() > properties.minTrackP &&
                        piplus_state.p() > properties.minTrackP;

  return decision;
}

__device__ void kplus_to_three_tracks_line::kplus_to_three_tracks_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto two_body_seed = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));
    const float pt = two_body_seed->vertex().pt();
    // Calculate the TwoBodySeed mass
    const float m_two_body_seed = particle.m12(Allen::mEl, Allen::mEl);

    properties.histogramTwoBodySeedMass.increment(m_two_body_seed);
    properties.histogramTwoBodySeedPt.increment(pt);
  }
}

__device__ bool kplus_to_three_tracks_line::kplus_to_three_tracks_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& particle = std::get<0>(input);
    // const auto two_body_seed = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));
    // Use the following variables in bandwidth division
    parameters.min_pt[index] = particle.minpt(); // This should range in [250., 2000.]
    parameters.min_ip[index] = particle.minip(); // This should range in [0.06, 2.0]
  }
  return sel;
}
