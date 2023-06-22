
/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "KsToPiPiLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters)

void kstopipi_line::kstopipi_line_t::init()
{
  Line<kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters>::init();
#ifndef ALLEN_STANDALONE
  histogram_ks_mass = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "ks_mass",
     "m(ks)",
     {property<histogram_ks_mass_nbins_t>(), property<histogram_ks_mass_min_t>(), property<histogram_ks_mass_max_t>()}},
    {}};
  histogram_ks_pt = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "ks_pt",
     "pT(ks)",
     {property<histogram_ks_pt_nbins_t>(), property<histogram_ks_pt_min_t>(), property<histogram_ks_pt_max_t>()}},
    {}};
#endif
}

void kstopipi_line::kstopipi_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_ks_mass_t>(arguments, 100u);
  set_size<typename Parameters::dev_histogram_ks_pt_t>(arguments, 100u);
}

__device__ bool kstopipi_line::kstopipi_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const bool opposite_sign = vertex.charge() == 0;

  const bool decision = vertex.minipchi2() > parameters.minIPChi2 && opposite_sign == parameters.OppositeSign &&
                        vertex.vertex().chi2() < parameters.maxVertexChi2 && vertex.ip() < parameters.maxIP &&
                        vertex.m12(Allen::mPi, Allen::mPi) > parameters.minMass &&
                        vertex.m12(Allen::mPi, Allen::mPi) < parameters.maxMass &&
                        vertex.pv().position.z >= parameters.minZ && vertex.vertex().z() >= parameters.minZ;

  return decision;
}
void kstopipi_line::kstopipi_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_ks_mass_t>(arguments, 0, context);
  Allen::memset_async<dev_histogram_ks_pt_t>(arguments, 0, context);
}

__device__ void kstopipi_line::kstopipi_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto ks = std::get<0>(input);
  if (sel) {
    parameters.sv_masses[index] = ks.m12(Allen::mPi, Allen::mPi);
    parameters.pt[index] = ks.vertex().pt();
    const float pt = ks.vertex().pt();
    parameters.mipchi2[index] = ks.minipchi2();
    const float m = ks.m12(Allen::mPi, Allen::mPi);
    if (m > parameters.histogram_ks_mass_min && m < parameters.histogram_ks_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_ks_mass_min) * parameters.histogram_ks_mass_nbins /
        (parameters.histogram_ks_mass_max - parameters.histogram_ks_mass_min));
      ++parameters.dev_histogram_ks_mass[bin];
    }
    if (pt > parameters.histogram_ks_pt_min && pt < parameters.histogram_ks_pt_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (pt - parameters.histogram_ks_pt_min) * parameters.histogram_ks_pt_nbins /
        (parameters.histogram_ks_pt_max - parameters.histogram_ks_pt_min));
      ++parameters.dev_histogram_ks_pt[bin];
    }
  }
}

void kstopipi_line::kstopipi_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {get<dev_histogram_ks_mass_t>(arguments),
                            histogram_ks_mass,
                            property<histogram_ks_mass_min_t>(),
                            property<histogram_ks_mass_max_t>()},
                std::tuple {get<dev_histogram_ks_pt_t>(arguments),
                            histogram_ks_pt,
                            property<histogram_ks_pt_min_t>(),
                            property<histogram_ks_pt_max_t>()}});
#endif
}
