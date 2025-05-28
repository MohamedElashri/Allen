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
#include "TrackElectronMVALine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(track_electron_mva_line::track_electron_mva_line_t, track_electron_mva_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned>
track_electron_mva_line::track_electron_mva_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto track = event_tracks.particle(i);

  return std::forward_as_tuple(track, event_number);
}

__device__ bool track_electron_mva_line::track_electron_mva_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> input)
{
  const auto& track = std::get<0>(input);
  const auto& event_number = std::get<1>(input);
  const auto event_tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const float corrected_pt = parameters.dev_brem_corrected_pt[track.get_index() + event_tracks.offset()];

  const auto nn = parameters.dev_electronidnn[event_tracks.offset() + track.get_index()];
  // Electron ID
  if (!track.is_electron() || !track.has_pv()) {
    return false;
  }

  const auto ptShift = (corrected_pt - properties.alpha);
  const auto maxPt = properties.maxPt;
  const auto minIPChi2 = properties.minIPChi2;
  const auto trackIPChi2 = track.ip_chi2();
  bool electronid_bool = ((properties.useNN) && nn > properties.minElectronNN) || !(properties.useNN);
  const bool decision =
    electronid_bool && track.state().chi2() / track.state().ndof() < properties.maxChi2Ndof &&
    ((ptShift > maxPt && trackIPChi2 > minIPChi2) ||
     (ptShift > properties.minPt && ptShift < maxPt &&
      logf(trackIPChi2) > properties.param1 / ((ptShift - properties.param2) * (ptShift - properties.param2)) +
                            (properties.param3 / maxPt) * (maxPt - ptShift) + logf(minIPChi2))) &&
    track.pv().position.z > properties.minBPVz;

  return decision;
}

__device__ bool track_electron_mva_line::track_electron_mva_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& track = std::get<0>(input);
    const auto& event_number = std::get<1>(input);
    const auto event_tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(
      parameters.dev_particle_container[0].container(event_number));
    const float corrected_pt = parameters.dev_brem_corrected_pt[track.get_index() + event_tracks.offset()];
    const auto nn = parameters.dev_electronidnn[event_tracks.offset() + track.get_index()];
    parameters.ipchi2[index] = track.ip_chi2();
    parameters.pt[index] = track.state().pt();
    parameters.pt_corrected[index] = corrected_pt;
    parameters.electron_nn[index] = nn;
  }
  return sel;
}
