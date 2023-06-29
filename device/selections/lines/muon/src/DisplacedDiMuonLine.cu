/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DisplacedDiMuonLine.cuh"

INSTANTIATE_LINE(displaced_di_muon_line::displaced_di_muon_line_t, displaced_di_muon_line::Parameters)

void displaced_di_muon_line::displaced_di_muon_line_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_displaced_dimuon_mass = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "displaced_dimuon_mass",
     "m(displ)",
     {property<histogram_mass_nbins_t>(), property<histogram_mass_min_t>(), property<histogram_mass_max_t>()}},
    {}};
#endif
}

void displaced_di_muon_line::displaced_di_muon_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_mass_t>(arguments, property<histogram_mass_nbins_t>());
}

__device__ bool displaced_di_muon_line::displaced_di_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.minipchi2() < parameters.dispMinIPChi2) return false;
  // TODO temporary hardcoded mass cut to reduce CPU-GPU differences
  if (vertex.mdimu() < 215.f) return false;

  bool decision = vertex.vertex().chi2() > 0 && vertex.vertex().chi2() < parameters.maxVertexChi2 &&
                  vertex.eta() > parameters.dispMinEta && vertex.eta() < parameters.dispMaxEta &&
                  vertex.minpt() > parameters.minDispTrackPt && vertex.vertex().z() >= parameters.minZ;
  return decision;
}

void displaced_di_muon_line::displaced_di_muon_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_mass_t>(arguments, 0, context);
}

__device__ void displaced_di_muon_line::displaced_di_muon_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto vertex = std::get<0>(input);
    const auto m = vertex.mdimu();
    if (m > parameters.histogram_mass_min && m < parameters.histogram_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_mass_min) * parameters.histogram_mass_nbins /
        (parameters.histogram_mass_max - parameters.histogram_mass_min));
      ++parameters.dev_histogram_mass[bin];
    }
  }
}

void displaced_di_muon_line::displaced_di_muon_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {get<dev_histogram_mass_t>(arguments),
                histogram_displaced_dimuon_mass,
                property<histogram_mass_min_t>(),
                property<histogram_mass_max_t>()});
#endif
}
