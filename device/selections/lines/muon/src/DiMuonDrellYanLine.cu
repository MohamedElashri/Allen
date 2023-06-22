/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DiMuonDrellYanLine.cuh"

INSTANTIATE_LINE(di_muon_drell_yan_line::di_muon_drell_yan_line_t, di_muon_drell_yan_line::Parameters)

void di_muon_drell_yan_line::di_muon_drell_yan_line_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_Z_mass = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "Z_mass",
     "m(mu+mu-)",
     {property<histogram_Z_mass_nbins_t>(), property<histogram_Z_mass_min_t>(), property<histogram_Z_mass_max_t>()}},
    {}};
  histogram_Z_mass_ss = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "Z_mass_ss",
     "m(mu+mu+)",
     {property<histogram_Z_mass_nbins_t>(), property<histogram_Z_mass_min_t>(), property<histogram_Z_mass_max_t>()}},
    {}};
#endif
}

void di_muon_drell_yan_line::di_muon_drell_yan_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_Z_mass_t>(arguments, 100u);
}

__device__ bool di_muon_drell_yan_line::di_muon_drell_yan_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto& particle = std::get<0>(input);

  const bool opposite_sign = particle.charge() == 0;
  if (opposite_sign != parameters.OppositeSign) return false;

  const auto& vertex = particle.vertex();

  if (vertex.chi2() < 0) {
    return false; // this should never happen.
  }

  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  const bool decision = particle.is_dimuon() && vertex.chi2() <= parameters.maxVertexChi2 &&
                        particle.doca12() <= parameters.maxDoca && trk1->state().pt() >= parameters.minTrackPt &&
                        trk1->state().p() >= parameters.minTrackP && trk1->state().eta() <= parameters.maxTrackEta

                        && trk2->state().pt() >= parameters.minTrackPt && trk2->state().p() >= parameters.minTrackP &&
                        trk2->state().eta() <= parameters.maxTrackEta

                        && particle.mdimu() >= parameters.minMass && particle.mdimu() <= parameters.maxMass

                        && particle.pv().position.z >= parameters.minZ;

  return decision;
}

void di_muon_drell_yan_line::di_muon_drell_yan_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_Z_mass_t>(arguments, 0, context);
}

__device__ void di_muon_drell_yan_line::di_muon_drell_yan_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto& vertex = std::get<0>(input);
    const auto m = vertex.mdimu();
    if (m > parameters.histogram_Z_mass_min && m < parameters.histogram_Z_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_Z_mass_min) * parameters.histogram_Z_mass_nbins /
        (parameters.histogram_Z_mass_max - parameters.histogram_Z_mass_min));
      ++parameters.dev_histogram_Z_mass[bin];
    }
  }
}

__device__ void di_muon_drell_yan_line::di_muon_drell_yan_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& vertex = std::get<0>(input);
    const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
    const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

    const auto m = vertex.mdimu();
    parameters.mass[index] = m;
    parameters.transverse_momentum[index] = std::min(trk1->state().pt(), trk2->state().pt());
  }
}

void di_muon_drell_yan_line::di_muon_drell_yan_line_t::output_monitor(
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
                  histogram_Z_mass,
                  property<histogram_Z_mass_min_t>(),
                  property<histogram_Z_mass_max_t>()});
  }
  else {
    gaudi_monitoring::fill(
      arguments,
      context,
      std::tuple {get<dev_histogram_Z_mass_t>(arguments),
                  histogram_Z_mass_ss,
                  property<histogram_Z_mass_min_t>(),
                  property<histogram_Z_mass_max_t>()});
  }
#endif
}
