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

  bool passes_prompt_selection = passes_common_selection && brem_corrected_minpt > properties.minPTprompt &&
                                 track1->ip_chi2() < properties.trackIPChi2Threshold &&
                                 track2->ip_chi2() < properties.trackIPChi2Threshold;

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

void lowmass_dielectron_line::lowmass_dielectron_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, runtime_options, constants);
  set_size<dev_die_masses_raw_t>(
    arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_masses_bremcorr_t>(
    arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_pts_raw_t>(
    arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_pts_bremcorr_t>(
    arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_e_minpts_raw_t>(
    arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_e_minpt_bremcorr_t>(
    arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_minipchi2_t>(
    arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_ip_t>(arguments, lowmass_dielectron_line::lowmass_dielectron_line_t::get_decisions_size(arguments));
}

void lowmass_dielectron_line::lowmass_dielectron_line_t::init_tuples(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_die_masses_raw_t>(arguments, -1, context);
  Allen::memset_async<dev_die_masses_bremcorr_t>(arguments, -1, context);
  Allen::memset_async<dev_die_pts_raw_t>(arguments, -1, context);
  Allen::memset_async<dev_die_pts_bremcorr_t>(arguments, -1, context);
  Allen::memset_async<dev_die_minipchi2_t>(arguments, -1, context);
  Allen::memset_async<dev_die_ip_t>(arguments, -1, context);
  Allen::memset_async<dev_e_minpts_raw_t>(arguments, -1, context);
  Allen::memset_async<dev_e_minpt_bremcorr_t>(arguments, -1, context);
}

__device__ void lowmass_dielectron_line::lowmass_dielectron_line_t::fill_tuples(
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
  }
}

void lowmass_dielectron_line::lowmass_dielectron_line_t::output_tuples(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  [[maybe_unused]] const RuntimeOptions& runtime_options,
  [[maybe_unused]] const Allen::Context& context) const
{
  const auto v_die_masses_raw = make_host_buffer<dev_die_masses_raw_t>(arguments, context);
  const auto v_die_masses_bremcorr = make_host_buffer<dev_die_masses_bremcorr_t>(arguments, context);
  const auto v_die_pts_raw = make_host_buffer<dev_die_pts_raw_t>(arguments, context);
  const auto v_die_pts_bremcorr = make_host_buffer<dev_die_pts_bremcorr_t>(arguments, context);
  const auto v_die_minipchi2 = make_host_buffer<dev_die_minipchi2_t>(arguments, context);
  const auto v_dev_die_ip = make_host_buffer<dev_die_ip_t>(arguments, context);
  const auto v_e_minpts_raw = make_host_buffer<dev_e_minpts_raw_t>(arguments, context);
  const auto v_e_minpt_bremcorr = make_host_buffer<dev_e_minpt_bremcorr_t>(arguments, context);

  auto handler = runtime_options.root_service->handle(name());
  auto tree = handler.tree("monitor_tree");

  float die_mass_raw;
  float die_mass_bremcorr;
  float die_pt_raw;
  float die_pt_bremcorr;
  float die_minipchi2;
  float die_ip;
  float e_minpt_raw;
  float e_minpt_bremcorr;

  handler.branch(tree, "die_mass_raw", die_mass_raw);
  handler.branch(tree, "die_mass_bremcorr", die_mass_bremcorr);
  handler.branch(tree, "die_pt_raw", die_pt_raw);
  handler.branch(tree, "die_minipchi2", die_minipchi2);
  handler.branch(tree, "die_pt_bremcorr", die_pt_bremcorr);
  handler.branch(tree, "die_ip", die_ip);
  handler.branch(tree, "e_minpt_raw", e_minpt_raw);
  handler.branch(tree, "e_minpt_bremcorr", e_minpt_bremcorr);

  unsigned n_svs = v_die_masses_raw.size();

  for (unsigned i = 0; i < n_svs; i++) {
    die_mass_raw = v_die_masses_raw[i];
    die_mass_bremcorr = v_die_masses_bremcorr[i];
    die_pt_raw = v_die_pts_raw[i];
    die_pt_bremcorr = v_die_pts_bremcorr[i];
    die_minipchi2 = v_die_minipchi2[i];
    die_ip = v_dev_die_ip[i];
    e_minpt_raw = v_e_minpts_raw[i];
    e_minpt_bremcorr = v_e_minpt_bremcorr[i];
    if (die_mass_raw > -1) {
      tree->Fill();
    }
  }
  tree->Write(0, TObject::kOverwrite);
}
