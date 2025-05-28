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
#include "LowMassDielectronLine.cuh"
#include "BinarySearch.cuh"

INSTANTIATE_LINE(lowmass_dielectron_line::lowmass_dielectron_line_t, lowmass_dielectron_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, unsigned>
lowmass_dielectron_line::lowmass_dielectron_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);

  return std::forward_as_tuple(vertex, event_number);
}

__device__ bool lowmass_dielectron_line::lowmass_dielectron_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, unsigned> input)
{
  const Allen::Views::Physics::CompositeParticle vertex = std::get<0>(input);
  const unsigned event_number = std::get<1>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const float nn_track1 =
    parameters.dev_electronid_evaluation[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const float nn_track2 =
    parameters.dev_electronid_evaluation[parameters.dev_track_offsets[event_number] + track2->get_index()];
  bool is_dielectron = false;
  if (properties.useNN)
    is_dielectron = nn_track1 > properties.nnCut && nn_track2 > properties.nnCut;
  else
    is_dielectron = vertex.is_dielectron();
  const float brem_corrected_pt1 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const float brem_corrected_pt2 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track2->get_index()];

  const float raw_pt1 = track1->state().pt();
  const float raw_pt2 = track2->state().pt();

  float brem_p_correction_ratio_trk1 = 0.f;
  float brem_p_correction_ratio_trk2 = 0.f;
  if (track1->state().p() > 0.f) {
    brem_p_correction_ratio_trk1 = brem_corrected_pt1 / raw_pt1;
  }
  if (track2->state().p() > 0.f) {
    brem_p_correction_ratio_trk2 = brem_corrected_pt2 / raw_pt2;
  }
  const float brem_corrected_dielectron_mass =
    vertex.m12(0.510999f, 0.510999f) * sqrtf(brem_p_correction_ratio_trk1 * brem_p_correction_ratio_trk2);

  const float brem_corrected_dielectron_pt = brem_corrected_pt1 + brem_corrected_pt2;

  const float brem_corrected_minpt = min(brem_corrected_pt1, brem_corrected_pt2);

  const bool is_same_sign = (track1->state().qop() * track2->state().qop()) > 0;

  bool passes_common_selection = vertex.doca12() < properties.maxDOCA &&
                                 vertex.vertex().chi2() < properties.maxVtxChi2 &&
                                 brem_corrected_dielectron_pt > properties.minDielectronPT;

  bool passes_prompt_selection = passes_common_selection && brem_corrected_minpt > properties.minPTprompt;
  // no cut on the IP for prompt, actually NoIP.

  bool passes_displaced_selection = passes_common_selection && brem_corrected_minpt > properties.minPTdisplaced &&
                                    track1->ip_chi2() > properties.trackIPChi2Threshold &&
                                    track2->ip_chi2() > properties.trackIPChi2Threshold;

  // Electron ID
  if (!is_dielectron) {
    return false;
  }

  bool decision = (is_same_sign == properties.ss_on) && brem_corrected_dielectron_mass > properties.minMass &&
                  brem_corrected_dielectron_mass < properties.maxMass && vertex.vertex().z() >= properties.minZ;

  // Select prompt or displaced candidates
  decision &=
    ((properties.selectPrompt && passes_prompt_selection) || (!properties.selectPrompt && passes_displaced_selection));

  bool decision_no_mass_prompt_only = (is_same_sign == properties.ss_on) && vertex.vertex().z() >= properties.minZ &&
                                      properties.selectPrompt && passes_prompt_selection;
  if (decision_no_mass_prompt_only) {
    auto m12 = vertex.m12(0.510999, 0.510999);
    properties.histogram_dielectron_masses.increment(m12);
    properties.histogram_dielectron_masses_brem.increment(brem_corrected_dielectron_mass);
  }

  return decision;
}

__device__ bool lowmass_dielectron_line::lowmass_dielectron_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, unsigned> input,
  unsigned index,
  bool sel)
{
  const Allen::Views::Physics::CompositeParticle vertex = std::get<0>(input);
  const unsigned event_number = std::get<1>(input);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const float brem_corrected_pt1 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const float brem_corrected_pt2 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track2->get_index()];

  const float raw_pt1 = track1->state().pt();
  const float raw_pt2 = track2->state().pt();
  const float nn_track1 =
    parameters.dev_electronid_evaluation[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const float nn_track2 =
    parameters.dev_electronid_evaluation[parameters.dev_track_offsets[event_number] + track2->get_index()];
  float brem_p_correction_ratio_trk1 = 0.f;
  float brem_p_correction_ratio_trk2 = 0.f;
  if (track1->state().p() > 0.f) {
    brem_p_correction_ratio_trk1 = brem_corrected_pt1 / raw_pt1;
  }
  if (track2->state().p() > 0.f) {
    brem_p_correction_ratio_trk2 = brem_corrected_pt2 / raw_pt2;
  }
  const float brem_corrected_dielectron_mass =
    vertex.m12(0.510999f, 0.510999f) * sqrtf(brem_p_correction_ratio_trk1 * brem_p_correction_ratio_trk2);

  const float brem_corrected_dielectron_pt = brem_corrected_pt1 + brem_corrected_pt2;

  const float brem_corrected_minpt = min(brem_corrected_pt1, brem_corrected_pt2);

  if (sel) {
    parameters.dev_die_masses_raw[index] = vertex.m12(0.510999, 0.510999);
    parameters.dev_die_masses_bremcorr[index] = brem_corrected_dielectron_mass;
    parameters.dev_die_pts_raw[index] = vertex.sumpt();
    parameters.dev_die_pts_bremcorr[index] = brem_corrected_dielectron_pt;
    parameters.dev_die_minipchi2[index] = vertex.minipchi2();
    parameters.dev_die_ip[index] = vertex.ip();
    parameters.dev_e_minpts_raw[index] = vertex.minpt();
    parameters.dev_e_minpt_bremcorr[index] = brem_corrected_minpt;
    parameters.dev_electron_nn[index] = min(nn_track1, nn_track2);
  }
  return sel;
}
