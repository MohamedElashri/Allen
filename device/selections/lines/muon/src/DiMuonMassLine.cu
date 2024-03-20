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
#include "DiMuonMassLine.cuh"

INSTANTIATE_LINE(di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters)

void di_muon_mass_line::di_muon_mass_line_t::init()
{
  Line<di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters>::init();
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
__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
di_muon_mass_line::di_muon_mass_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto particle = event_tracks.particle(i);
  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  const auto chi2corr1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const auto chi2corr2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk2->get_index()];

  return std::forward_as_tuple(particle, max(chi2corr1, chi2corr2));
}
__device__ bool di_muon_mass_line::di_muon_mass_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, float> input)
{
  const auto vertex = std::get<0>(input);
  const auto maxchi2muon = std::get<1>(input);
  const bool opposite_sign = vertex.charge() == 0;

  return maxchi2muon < parameters.maxChi2Muon && vertex.is_dimuon() && opposite_sign == parameters.OppositeSign &&
         vertex.minipchi2() >= parameters.minIPChi2 && vertex.doca12() <= parameters.maxDoca &&
         vertex.mdimu() >= parameters.minMass && vertex.minpt() >= parameters.minHighMassTrackPt &&
         vertex.minp() >= parameters.minHighMassTrackP && vertex.vertex().chi2() > 0 &&
         vertex.vertex().chi2() < parameters.maxVertexChi2 && vertex.vertex().z() >= parameters.minZ &&
         vertex.pv().position.z >= parameters.minZ;
}

void di_muon_mass_line::di_muon_mass_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_Jpsi_mass_t>(arguments, 0, context);
}

__device__ void di_muon_mass_line::di_muon_mass_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, float> input,
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
      atomicAdd(&parameters.dev_histogram_Jpsi_mass[bin], 1);
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

__device__ void di_muon_mass_line::di_muon_mass_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, float> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    parameters.ipchi2[index] = particle.minipchi2();
    parameters.pt[index] = particle.minpt();
  }
}
