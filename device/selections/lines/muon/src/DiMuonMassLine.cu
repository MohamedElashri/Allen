/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DiMuonMassLine.cuh"

INSTANTIATE_LINE(di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters)

void di_muon_mass_line::di_muon_mass_line_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_Jpsi_mass = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                     "Jpsi_mass",
                                                                     "m(J/Psi)",
                                                                     {property<histogram_Jpsi_mass_nbins_t>(),
                                                                      property<histogram_Jpsi_mass_min_t>(),
                                                                      property<histogram_Jpsi_mass_max_t>()}},
                                                                    {}};
#endif
}

void di_muon_mass_line::di_muon_mass_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_Jpsi_mass_t>(arguments, 100u);
}

__device__ bool di_muon_mass_line::di_muon_mass_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const bool opposite_sign = vertex.charge() == 0;

  return vertex.is_dimuon() && opposite_sign == parameters.OppositeSign && vertex.minipchi2() >= parameters.minIPChi2 &&
         vertex.doca12() <= parameters.maxDoca && vertex.mdimu() >= parameters.minMass &&
         vertex.minpt() >= parameters.minHighMassTrackPt && vertex.minp() >= parameters.minHighMassTrackP &&
         vertex.vertex().chi2() > 0 && vertex.vertex().chi2() < parameters.maxVertexChi2 &&
         vertex.vertex().z() >= parameters.minZ && vertex.pv().position.z >= parameters.minZ;
}

void di_muon_mass_line::di_muon_mass_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_Jpsi_mass_t>(arguments, 0, context);
}

__device__ void di_muon_mass_line::di_muon_mass_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto m = particle.m();
    if (m > parameters.histogram_Jpsi_mass_min && m < parameters.histogram_Jpsi_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_Jpsi_mass_min) * parameters.histogram_Jpsi_mass_nbins /
        (parameters.histogram_Jpsi_mass_max - parameters.histogram_Jpsi_mass_min));
      ++parameters.dev_histogram_Jpsi_mass[bin];
    }
  }
}

void di_muon_mass_line::di_muon_mass_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {get<dev_histogram_Jpsi_mass_t>(arguments),
                histogram_Jpsi_mass,
                property<histogram_Jpsi_mass_min_t>(),
                property<histogram_Jpsi_mass_max_t>()});
#endif
}
