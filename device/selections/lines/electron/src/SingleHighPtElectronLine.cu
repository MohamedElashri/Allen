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
#include "SingleHighPtElectronLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(single_high_pt_electron_line::single_high_pt_electron_line_t, single_high_pt_electron_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float>
single_high_pt_electron_line::single_high_pt_electron_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto track = event_tracks.particle(i);

  const bool is_electron = track.is_electron();

  const float corrected_pt = parameters.dev_brem_corrected_pt[i + event_tracks.offset()];

  return std::forward_as_tuple(track, is_electron, corrected_pt);
}

__device__ bool single_high_pt_electron_line::single_high_pt_electron_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float> input)
{
  const auto& track = std::get<0>(input);
  const auto& is_electron = std::get<1>(input);
  const auto& corrected_pt = std::get<2>(input);

  // Electron ID
  if (!is_electron) {
    return false;
  }

  const bool decision = corrected_pt > properties.singleMinPt &&
                        track.state().chi2() / track.state().ndof() < properties.maxChi2Ndof &&
                        track.state().z() >= properties.minZ;
  return decision;
}

__device__ bool single_high_pt_electron_line::single_high_pt_electron_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float> input,
  unsigned index,
  bool sel)
{
  if (sel) parameters.pt_corrected[index] = std::get<2>(input);
  return sel;
}
