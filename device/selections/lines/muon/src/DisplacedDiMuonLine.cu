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
#include "DisplacedDiMuonLine.cuh"
#include <unistd.h>

INSTANTIATE_LINE(displaced_di_muon_line::displaced_di_muon_line_t, displaced_di_muon_line::Parameters)

void displaced_di_muon_line::displaced_di_muon_line_t::init()
{
  Line<displaced_di_muon_line::displaced_di_muon_line_t, displaced_di_muon_line::Parameters>::init();
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

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
displaced_di_muon_line::displaced_di_muon_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const unsigned idx1_with_offset = parameters.dev_track_offsets[event_number] + track1->get_index();
  const unsigned idx2_with_offset = parameters.dev_track_offsets[event_number] + track2->get_index();
  const auto chi2corr1 = parameters.dev_chi2muon[idx1_with_offset];
  const auto chi2corr2 = parameters.dev_chi2muon[idx2_with_offset];

  return std::forward_as_tuple(vertex, max(chi2corr1, chi2corr2));
}

__device__ bool displaced_di_muon_line::displaced_di_muon_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, float> input)
{
  const auto vertex = std::get<0>(input);
  const auto maxchi2muon = std::get<1>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.minipchi2() < parameters.dispMinIPChi2) return false;
  // TODO temporary hardcoded mass cut to reduce CPU-GPU differences
  if (vertex.mdimu() < 215.f) return false;

  bool decision = maxchi2muon < parameters.maxChi2Muon && vertex.vertex().chi2() > 0 &&
                  vertex.vertex().chi2() < parameters.maxVertexChi2 && vertex.eta() > parameters.dispMinEta &&
                  vertex.eta() < parameters.dispMaxEta && vertex.minpt() > parameters.minDispTrackPt &&
                  vertex.vertex().z() >= parameters.minZ;
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
  std::tuple<const Allen::Views::Physics::CompositeParticle, float> input,
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
      atomicAdd(&parameters.dev_histogram_mass[bin], 1);
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
