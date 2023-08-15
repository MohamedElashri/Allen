/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "D2PiPiLine.cuh"

INSTANTIATE_LINE(d2pipi_line::d2pipi_line_t, d2pipi_line::Parameters)

void d2pipi_line::d2pipi_line_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_d02pipi_mass = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                        "d02pipi_mass",
                                                                        "m(D0)",
                                                                        {property<histogram_d02pipi_mass_nbins_t>(),
                                                                         property<histogram_d02pipi_mass_min_t>(),
                                                                         property<histogram_d02pipi_mass_max_t>()}},
                                                                       {}};
  histogram_d02pipi_pt = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                      "d02pipi_pt",
                                                                      "pT(D0)",
                                                                      {property<histogram_d02pipi_pt_nbins_t>(),
                                                                       property<histogram_d02pipi_pt_min_t>(),
                                                                       property<histogram_d02pipi_pt_max_t>()}},
                                                                     {}};
#endif
}

void d2pipi_line::d2pipi_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_d02pipi_mass_t>(arguments, 100u);
  set_size<typename Parameters::dev_histogram_d02pipi_pt_t>(arguments, 100u);
}

__device__ bool d2pipi_line::d2pipi_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const bool opposite_sign = particle.charge() == 0;
  if (opposite_sign != parameters.OppositeSign) return false;
  const auto vertex = particle.vertex();
  if (vertex.chi2() < 0) {
    return false;
  }
  const bool decision = vertex.pt() > parameters.minComboPt && vertex.chi2() < parameters.maxVertexChi2 &&
                        particle.eta() > parameters.minEta && particle.eta() < parameters.maxEta &&
                        particle.doca12() < parameters.maxDOCA && particle.minpt() > parameters.minTrackPt &&
                        particle.has_pv() && particle.minip() > parameters.minTrackIP &&
                        particle.ctau(Allen::mDz) > parameters.ctIPScale * parameters.minTrackIP &&
                        fabsf(particle.m12(Allen::mPi, Allen::mPi) - Allen::mDz) < parameters.massWindow &&
                        vertex.z() >= parameters.minZ && particle.pv().position.z >= parameters.minZ;

  return decision;
}

void d2pipi_line::d2pipi_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_d02pipi_mass_t>(arguments, 0, context);
  Allen::memset_async<dev_histogram_d02pipi_pt_t>(arguments, 0, context);
}

__device__ void d2pipi_line::d2pipi_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  const auto particle = std::get<0>(input);
  const auto vertex = particle.vertex();
  if (sel) {
    const float m1 = particle.m12(Allen::mPi, Allen::mPi);
    const float pt = vertex.pt();
    if (m1 > parameters.histogram_d02pipi_mass_min && m1 < parameters.histogram_d02pipi_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m1 - parameters.histogram_d02pipi_mass_min) * parameters.histogram_d02pipi_mass_nbins /
        (parameters.histogram_d02pipi_mass_max - parameters.histogram_d02pipi_mass_min));
      ++parameters.dev_histogram_d02pipi_mass[bin];
    }
    if (pt > parameters.histogram_d02pipi_pt_min && pt < parameters.histogram_d02pipi_pt_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (pt - parameters.histogram_d02pipi_pt_min) * parameters.histogram_d02pipi_pt_nbins /
        (parameters.histogram_d02pipi_pt_max - parameters.histogram_d02pipi_pt_min));
      ++parameters.dev_histogram_d02pipi_pt[bin];
    }
  }
}

void d2pipi_line::d2pipi_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {get<dev_histogram_d02pipi_mass_t>(arguments),
                            histogram_d02pipi_mass,
                            property<histogram_d02pipi_mass_min_t>(),
                            property<histogram_d02pipi_mass_max_t>()},
                std::tuple {get<dev_histogram_d02pipi_pt_t>(arguments),
                            histogram_d02pipi_pt,
                            property<histogram_d02pipi_pt_min_t>(),
                            property<histogram_d02pipi_pt_max_t>()}});
#endif
}

__device__ void d2pipi_line::d2pipi_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& particle = std::get<0>(input);
    // Use the following variables in bandwidth division
    parameters.min_pt[index] = particle.minpt(); // This should range in [800., 2000.]
    parameters.min_ip[index] = particle.minip(); // This should range in [0.06, 0.15]
    parameters.D0_ct[index] = particle.ctau(Allen::mDz);
  }
}
