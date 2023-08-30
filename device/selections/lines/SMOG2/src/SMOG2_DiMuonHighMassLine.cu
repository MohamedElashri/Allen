/*****************************************************************************\
 * (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_DiMuonHighMassLine.cuh"

INSTANTIATE_LINE(SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t, SMOG2_dimuon_highmass_line::Parameters)

__device__ bool SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto& vtx = std::get<0>(input);
  if (vtx.vertex().chi2() < 0) {
    return false;
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vtx.child(1));

  bool decision = vtx.vertex().z() < parameters.maxZ && vtx.is_dimuon() && vtx.doca12() < parameters.maxDoca &&
                  trk1->chi2() / trk1->ndof() < parameters.maxTrackChi2Ndf &&
                  trk2->chi2() / trk2->ndof() < parameters.maxTrackChi2Ndf && vtx.mdimu() >= parameters.minMass &&
                  vtx.minpt() >= parameters.minTrackPt && vtx.minp() >= parameters.minTrackP &&
                  vtx.vertex().chi2() < parameters.maxVertexChi2 && vtx.vertex().z() >= parameters.minZ &&
                  vtx.charge() == parameters.CombCharge;
  if (vtx.has_pv()) decision = decision && vtx.pv().position.z < parameters.maxZ;

  return decision;
}

void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::init()
{
  Line<SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t, SMOG2_dimuon_highmass_line::Parameters>::init();
#ifndef ALLEN_STANDALONE
  histogram_smogdimuon_mass =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "SMOG2_dimuon_mass",
                                                 "m(#mu#mu)",
                                                 {property<histogram_smogdimuon_mass_nbins_t>(),
                                                  property<histogram_smogdimuon_mass_min_t>(),
                                                  property<histogram_smogdimuon_mass_max_t>()}},
                                                {}};
  histogram_smogdimuon_svz = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                          "smogdimuon_svz",
                                                                          "SV_z(smogdimuon)",
                                                                          {property<histogram_smogdimuon_svz_nbins_t>(),
                                                                           property<histogram_smogdimuon_svz_min_t>(),
                                                                           property<histogram_smogdimuon_svz_max_t>()}},
                                                                         {}};
#endif
}

void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_smogdimuon_mass_t>(
    arguments, property<histogram_smogdimuon_mass_nbins_t>());
  set_size<typename Parameters::dev_histogram_smogdimuon_svz_t>(
    arguments, property<histogram_smogdimuon_svz_nbins_t>());
}

void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_smogdimuon_mass_t>(arguments, 0, context);
  Allen::memset_async<dev_histogram_smogdimuon_svz_t>(arguments, 0, context);
}

__device__ void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto dimuon = std::get<0>(input);
  if (sel) {
    parameters.smogdimuon_masses[index] = dimuon.mdimu();
    parameters.smogdimuon_svz[index] = dimuon.vertex().z();

    const float svz = dimuon.vertex().z();
    const float m = dimuon.mdimu();
    if (m > parameters.histogram_smogdimuon_mass_min && m < parameters.histogram_smogdimuon_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_smogdimuon_mass_min) * parameters.histogram_smogdimuon_mass_nbins /
        (parameters.histogram_smogdimuon_mass_max - parameters.histogram_smogdimuon_mass_min));
      ++parameters.dev_histogram_smogdimuon_mass[bin];
    }
    if (svz > parameters.histogram_smogdimuon_svz_min && svz < parameters.histogram_smogdimuon_svz_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (svz - parameters.histogram_smogdimuon_svz_min) * parameters.histogram_smogdimuon_svz_nbins /
        (parameters.histogram_smogdimuon_svz_max - parameters.histogram_smogdimuon_svz_min));
      ++parameters.dev_histogram_smogdimuon_svz[bin];
    }
  }
}

void SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {get<dev_histogram_smogdimuon_mass_t>(arguments),
                            histogram_smogdimuon_mass,
                            property<histogram_smogdimuon_mass_min_t>(),
                            property<histogram_smogdimuon_mass_max_t>()},
                std::tuple {get<dev_histogram_smogdimuon_svz_t>(arguments),
                            histogram_smogdimuon_svz,
                            property<histogram_smogdimuon_svz_min_t>(),
                            property<histogram_smogdimuon_svz_max_t>()}});
#endif
}
