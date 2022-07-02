/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "LowMassNoipDielectronLine.cuh"

INSTANTIATE_LINE(lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t, lowmass_noip_dielectron_line::Parameters)

__device__ std::tuple<
  const Allen::Views::Physics::CompositeParticle,
  const bool,
  const bool,
  const float,
  const float,
  const float,
  const bool,
  const bool>
lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_input(
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
  if (track1->state().p() > 0.f) {
    brem_p_correction_ratio_trk1 = brem_corrected_pt1 / raw_pt1;
  }
  if (track2->state().p() > 0.f) {
    brem_p_correction_ratio_trk2 = brem_corrected_pt2 / raw_pt2;
  }
  const float brem_corrected_dielectron_mass =
    vertex.m12(0.510999f, 0.510999f) * sqrtf(brem_p_correction_ratio_trk1 * brem_p_correction_ratio_trk2);

  const bool is_same_sign = (track1->state().qop() * track2->state().qop()) > 0;

  const bool passes_prompt_selection = parameters.dev_vertex_passes_prompt_selection[event_vertices.offset() + i];
  const bool passes_displaced_selection = parameters.dev_vertex_passes_displaced_selection[event_vertices.offset() + i];

  double brem_corrected_minpt = 0.;
  double brem_corrected_dielectron_pt = 0.;

  return std::forward_as_tuple(
    vertex,
    is_dielectron,
    is_same_sign,
    brem_corrected_minpt,
    brem_corrected_dielectron_mass,
    brem_corrected_dielectron_pt,
    passes_prompt_selection,
    passes_displaced_selection);
}

__device__ bool lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::select(
  const Parameters& parameters,
  std::tuple<
    const Allen::Views::Physics::CompositeParticle,
    const bool,
    const bool,
    const float,
    const float,
    const float,
    const bool,
    const bool> input)
{
  const bool is_dielectron = std::get<1>(input);
  const bool is_same_sign = std::get<2>(input);
  const float brem_corrected_dielectron_mass = std::get<4>(input);
  const bool passes_prompt_selection = std::get<6>(input);
  const bool passes_displaced_selection = std::get<7>(input);

  // Electron ID
  if (!is_dielectron) {
    return false;
  }

  bool decision = (is_same_sign == parameters.ss_on) && brem_corrected_dielectron_mass > parameters.minMass &&
                  brem_corrected_dielectron_mass < parameters.maxMass;

  // Select prompt or displaced candidates
  decision &=
    ((parameters.selectPrompt && passes_prompt_selection) || (!parameters.selectPrompt && passes_displaced_selection));

  return decision;
}

void lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, runtime_options, constants, host_buffers);
#ifdef WITH_ROOT
  set_size<dev_die_masses_raw_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_masses_bremcorr_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_pts_raw_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_pts_bremcorr_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_e_minpts_raw_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_e_minpt_bremcorr_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_minipchi2_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
  set_size<dev_die_ip_t>(
    arguments, lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::get_decisions_size(arguments));
#else
  set_size<dev_die_masses_raw_t>(arguments, 1);
  set_size<dev_die_masses_bremcorr_t>(arguments, 1);
  set_size<dev_die_pts_raw_t>(arguments, 1);
  set_size<dev_die_pts_bremcorr_t>(arguments, 1);
  set_size<dev_e_minpts_raw_t>(arguments, 1);
  set_size<dev_e_minpt_bremcorr_t>(arguments, 1);
  set_size<dev_die_minipchi2_t>(arguments, 1);
  set_size<dev_die_ip_t>(arguments, 1);
#endif
}

void lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::init_monitor(
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

__device__ void lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::monitor(
  const Parameters& parameters,
  std::tuple<
    const Allen::Views::Physics::CompositeParticle,
    const bool,
    const bool,
    const float,
    const float,
    const float,
    const bool,
    const bool> input,
  unsigned index,
  bool sel)
{
  const Allen::Views::Physics::CompositeParticle vertex = std::get<0>(input);
  const float brem_corrected_minpt = std::get<3>(input);
  const float brem_corrected_dielectron_mass = std::get<4>(input);
  const float brem_corrected_dielectron_pt = std::get<5>(input);
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

void lowmass_noip_dielectron_line::lowmass_noip_dielectron_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  [[maybe_unused]] const RuntimeOptions& runtime_options,
  const Allen::Context&) const
{
#ifdef WITH_ROOT
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
    die_mass_raw = v_die_masses_raw.at(i);
    die_mass_bremcorr = v_die_masses_bremcorr.at(i);
    die_pt_raw = v_die_pts_raw.at(i);
    die_pt_bremcorr = v_die_pts_bremcorr.at(i);
    die_minipchi2 = v_die_minipchi2.at(i);
    die_ip = v_dev_die_ip.at(i);
    e_minpt_raw = v_e_minpts_raw.at(i);
    e_minpt_bremcorr = v_e_minpt_bremcorr.at(i);
    if (die_mass_raw > -1) {
      tree->Fill();
    }
  }
  tree->Write(0, TObject::kOverwrite);
#endif
}
