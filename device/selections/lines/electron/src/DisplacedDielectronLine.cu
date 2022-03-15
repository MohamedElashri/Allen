/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DisplacedDielectronLine.cuh"

INSTANTIATE_LINE(displaced_dielectron_line::displaced_dielectron_line_t, displaced_dielectron_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float>
displaced_dielectron_line::displaced_dielectron_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);
  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const bool is_dielectron = vertex.is_dielectron();

  const float brem_corrected_minpt = min(
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk1->get_index()],
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk2->get_index()]);

  return std::forward_as_tuple(vertex, is_dielectron, brem_corrected_minpt);
}

__device__ bool displaced_dielectron_line::displaced_dielectron_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float> input)
{
  const auto vertex = std::get<0>(input);
  const bool is_dielectron = std::get<1>(input);
  const float brem_corrected_minpt = std::get<2>(input);

  // Electron ID
  if (!is_dielectron) {
    return false;
  }

  bool decision = vertex.minipchi2() > parameters.minIPChi2 && vertex.doca12() < parameters.maxDOCA &&
                  brem_corrected_minpt > parameters.minPT && vertex.vertex().chi2() < parameters.maxVtxChi2;

  return decision;
}
