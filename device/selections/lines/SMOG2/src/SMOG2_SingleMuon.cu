/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "SMOG2_SingleMuon.cuh"

// Explicit instantiation
INSTANTIATE_LINE(SMOG2_single_muon_line::SMOG2_single_muon_line_t, SMOG2_single_muon_line::Parameters)

__device__ bool SMOG2_single_muon_line::SMOG2_single_muon_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> input)
{
  const auto track = std::get<0>(input);
  const auto event_number = std::get<1>(input);

  const auto chi2corr = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + track.get_index()];

  const auto nn = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + track.get_index()];
  bool muonid_bool = false;
  if (properties.useNN) {
    muonid_bool = nn > properties.minMuonNN;
  }
  else {
    muonid_bool = chi2corr < properties.maxChi2Corr;
  }
  bool decision = muonid_bool && track.is_muon() && track.state().pt() > properties.MinPt &&
                  track.state().p() > properties.MinP &&
                  track.state().chi2() / track.state().ndof() < properties.maxChi2Ndof &&
                  track.state().z() < properties.maxBPVz && track.state().z() >= properties.minBPVz;
  if (track.has_pv()) decision = decision && track.pv().position.z < properties.maxBPVz;

  return decision;
}

__device__ std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned>
SMOG2_single_muon_line::SMOG2_single_muon_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto track = event_tracks.particle(i);

  return std::forward_as_tuple(track, event_number);
}

__device__ bool SMOG2_single_muon_line::SMOG2_single_muon_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto track = std::get<0>(input);
    const auto& event_number = std::get<1>(input);
    const auto nn = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + track.get_index()];
    const auto chi2corr = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + track.get_index()];
    parameters.ipchi2[index] = track.ip_chi2();
    parameters.pt[index] = track.state().pt();
    parameters.muonchi2[index] = chi2corr;
    parameters.muon_nn[index] = nn;
  }
  return sel;
}
