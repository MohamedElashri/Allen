/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HighMassDielectronLine.cuh"

INSTANTIATE_LINE(highmass_dielectron_line::highmass_dielectron_line_t, highmass_dielectron_line::Parameters)

void highmass_dielectron_line::highmass_dielectron_line_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_dielectron_Z_mass = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "dielectron_Z_mass_counts",
     "dielectron masses w/brem (Z)",
     {property<histogram_Z_mass_nbins_t>(), property<histogram_Z_mass_min_t>(), property<histogram_Z_mass_max_t>()}},
    {}};
  histogram_dielectron_upsilon_mass =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "dielectron_upsilon_mass_counts_ss",
                                                 "dielectron masses w/brem (Upsilon)",
                                                 {property<histogram_upsilon_mass_nbins_t>(),
                                                  property<histogram_upsilon_mass_min_t>(),
                                                  property<histogram_upsilon_mass_max_t>()}},
                                                {}};
#endif
}

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
  const Parameters& parameters,
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

  bool decision = (is_same_sign != parameters.OppositeSign) && (vertex.doca12() <= parameters.maxDoca) &&
                  (min_pt > parameters.minTrackPt) && trk1->state().eta() <= parameters.maxTrackEta &&
                  trk2->state().eta() <= parameters.maxTrackEta && (brem_corrected_minp > parameters.minTrackP) &&
                  brem_corrected_dielectron_mass > parameters.minMass &&
                  brem_corrected_dielectron_mass < parameters.maxMass && vertex.vertex().z() >= parameters.MinZ;

  return decision;
}

void highmass_dielectron_line::highmass_dielectron_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_Z_mass_t>(arguments, 0, context);
  Allen::memset_async<dev_histogram_upsilon_mass_t>(arguments, 0, context);
}

__device__ void highmass_dielectron_line::highmass_dielectron_line_t::monitor(
  const Parameters& parameters,
  std::
    tuple<const Allen::Views::Physics::CompositeParticle, const bool, const bool, const float, const float, const float>
      input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto& m = std::get<4>(input);
    if (m > parameters.histogram_Z_mass_min && m < parameters.histogram_Z_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_Z_mass_min) * parameters.histogram_Z_mass_nbins /
        (parameters.histogram_Z_mass_max - parameters.histogram_Z_mass_min));
      atomicAdd(&parameters.dev_histogram_Z_mass[bin], 1);
    }

    if (m > parameters.histogram_upsilon_mass_min && m < parameters.histogram_upsilon_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_upsilon_mass_min) * parameters.histogram_upsilon_mass_nbins /
        (parameters.histogram_upsilon_mass_max - parameters.histogram_upsilon_mass_min));
      atomicAdd(&parameters.dev_histogram_upsilon_mass[bin], 1);
    }
  }
}

void highmass_dielectron_line::highmass_dielectron_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  if (property<OppositeSign_t>()) {
    gaudi_monitoring::fill(
      arguments,
      context,
      std::tuple {get<dev_histogram_Z_mass_t>(arguments),
                  histogram_dielectron_Z_mass,
                  property<histogram_Z_mass_min_t>(),
                  property<histogram_Z_mass_max_t>()});

    gaudi_monitoring::fill(
      arguments,
      context,
      std::tuple {get<dev_histogram_upsilon_mass_t>(arguments),
                  histogram_dielectron_upsilon_mass,
                  property<histogram_upsilon_mass_min_t>(),
                  property<histogram_upsilon_mass_max_t>()});
  }
#endif
}

__device__ void highmass_dielectron_line::highmass_dielectron_line_t::fill_tuples(
  const Parameters& parameters,
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
}

void highmass_dielectron_line::highmass_dielectron_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_Z_mass_t>(arguments, 100u);
  set_size<typename Parameters::dev_histogram_upsilon_mass_t>(arguments, 100u);
}