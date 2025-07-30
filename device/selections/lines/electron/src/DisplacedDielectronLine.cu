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
#include "DisplacedDielectronLine.cuh"

INSTANTIATE_LINE(displaced_dielectron_line::displaced_dielectron_line_t, displaced_dielectron_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>
displaced_dielectron_line::displaced_dielectron_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);
  return std::forward_as_tuple(vertex, event_number);
}

__device__ bool displaced_dielectron_line::displaced_dielectron_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto& [vertex, event_number] = input;

  // Electron ID
  if (!vertex.is_dielectron()) {
    return false;
  }
  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const unsigned brem_corrected_minpt = std::min(
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk1->get_index()],
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk2->get_index()]);
  const auto nn1 = parameters.dev_electronidnn[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const auto nn2 = parameters.dev_electronidnn[parameters.dev_track_offsets[event_number] + trk2->get_index()];
  bool electronid_bool = true;
  if (properties.useNN) {
    electronid_bool = min(nn1, nn2) > properties.minElectronNN;
  }

  const bool opposite_sign = vertex.charge() == 0;
  if (opposite_sign != properties.oppositeSign) return false;

  const bool decision = vertex.has_pv() && vertex.minipchi2() > properties.minIPChi2 &&
                        vertex.doca12() < properties.maxDOCA && brem_corrected_minpt > properties.minPT &&
                        vertex.vertex().chi2() < properties.maxVtxChi2 && vertex.vertex().z() > properties.minZ &&
                        vertex.pv().position.z >= properties.minZ && electronid_bool;

  return decision;
}

__device__ bool displaced_dielectron_line::displaced_dielectron_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {

    const auto& [vertex, event_number] = input;
    const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
    const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
    const unsigned brem_corrected_minpt = std::min(
      parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk1->get_index()],
      parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk2->get_index()]);
    const auto nn1 = parameters.dev_electronidnn[parameters.dev_track_offsets[event_number] + trk1->get_index()];
    const auto nn2 = parameters.dev_electronidnn[parameters.dev_track_offsets[event_number] + trk2->get_index()];
    const auto particle = std::get<0>(input);
    parameters.ipchi2[index] = particle.minipchi2();
    parameters.pt[index] = brem_corrected_minpt;
    parameters.electron_nn[index] = min(nn1, nn2);
  }
  return sel;
}
