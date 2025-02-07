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
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input)
{
  const auto vertex = std::get<0>(input);
  const auto maxchi2muon = std::get<1>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.minipchi2() < properties.dispMinIPChi2) return false;
  // TODO temporary hardcoded mass cut to reduce CPU-GPU differences
  if (vertex.mdimu() < 215.f) return false;

  bool decision = maxchi2muon < properties.maxChi2Muon && vertex.vertex().chi2() > 0 &&
                  vertex.vertex().chi2() < properties.maxVertexChi2 && vertex.eta() > properties.dispMinEta &&
                  vertex.eta() < properties.dispMaxEta && vertex.minpt() > properties.minDispTrackPt &&
                  vertex.vertex().z() >= properties.minZ;
  return decision;
}

__device__ void displaced_di_muon_line::displaced_di_muon_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto vertex = std::get<0>(input);
    properties.histogram_displaced_dimuon_mass.increment(vertex.mdimu());
  }
}
