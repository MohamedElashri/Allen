/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HighMassDielectronLine.cuh"

INSTANTIATE_LINE(highmass_dielectron_line::highmass_dielectron_line_t, highmass_dielectron_line::Parameters)

__device__ std::
  tuple<const Allen::Views::Physics::CompositeParticle, const bool, const bool, const float, const float, const float>
  highmass_dielectron_line::highmass_dielectron_line_t::get_input(
    const Parameters& parameters,
    const unsigned event_number,
    const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const bool is_dielectron = vertex.is_dielectron();

  const float brem_corrected_pt1 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const float brem_corrected_pt2 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track2->get_index()];

  const float raw_pt1 = track1->state().pt();
  const float raw_pt2 = track2->state().pt();

  float brem_p_correction_ratio_trk1 = 0.f;
  float brem_p_correction_ratio_trk2 = 0.f;

  float brem_corrected_p2 = 0.f;
  float brem_corrected_p1 = 0.f;

  if (track1->state().p() > 0.f) {
    brem_p_correction_ratio_trk1 = brem_corrected_pt1 / raw_pt1;
    brem_corrected_p1 = track1->state().p() * brem_p_correction_ratio_trk1;
  }
  if (track2->state().p() > 0.f) {
    brem_p_correction_ratio_trk2 = brem_corrected_pt2 / raw_pt2;
    brem_corrected_p2 = track2->state().p() * brem_p_correction_ratio_trk2;
  }

  // dubious?
  const float brem_corrected_dielectron_mass =
    vertex.m12(0.510999f, 0.510999f) * sqrtf(brem_p_correction_ratio_trk1 * brem_p_correction_ratio_trk2);

  const bool is_same_sign = (track1->state().qop() * track2->state().qop()) > 0;

  float brem_corrected_minpt = min(brem_corrected_pt2, brem_corrected_pt1);
  float brem_corrected_minp = min(brem_corrected_p2, brem_corrected_p1);

  return std::forward_as_tuple(
    vertex, is_dielectron, is_same_sign, brem_corrected_minpt, brem_corrected_dielectron_mass, brem_corrected_minp);
}

__device__ bool highmass_dielectron_line::highmass_dielectron_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::
    tuple<const Allen::Views::Physics::CompositeParticle, const bool, const bool, const float, const float, const float>
      input)
{
  const Allen::Views::Physics::CompositeParticle vertex = std::get<0>(input);
  const bool is_dielectron = std::get<1>(input);
  const bool is_same_sign = std::get<2>(input);
  const float min_pt = std::get<3>(input);
  const float brem_corrected_dielectron_mass = std::get<4>(input);
  const float brem_corrected_minp = std::get<5>(input);

  // Electron ID
  if (!is_dielectron) {
    return false;
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  bool decision = (is_same_sign != properties.oppositeSign) && (vertex.doca12() <= properties.maxDoca) &&
                  (min_pt > properties.minTrackPt) && trk1->state().eta() <= properties.maxTrackEta &&
                  trk2->state().eta() <= properties.maxTrackEta && (brem_corrected_minp > properties.minTrackP) &&
                  brem_corrected_dielectron_mass > properties.minMass &&
                  brem_corrected_dielectron_mass < properties.maxMass && vertex.vertex().z() >= properties.minZ;

  return decision;
}

__device__ void highmass_dielectron_line::highmass_dielectron_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::
    tuple<const Allen::Views::Physics::CompositeParticle, const bool, const bool, const float, const float, const float>
      input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto& m = std::get<4>(input);
    properties.histogram_dielectron_Z_mass.increment(m);
    properties.histogram_dielectron_upsilon_mass.increment(m);
  }
}

__device__ bool highmass_dielectron_line::highmass_dielectron_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::
    tuple<const Allen::Views::Physics::CompositeParticle, const bool, const bool, const float, const float, const float>
      input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& m = std::get<4>(input);
    parameters.mass[index] = m;
  }
  return sel;
}
