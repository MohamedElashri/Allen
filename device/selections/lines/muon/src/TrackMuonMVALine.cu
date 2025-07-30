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
#include "TrackMuonMVALine.cuh"
#include <cwchar>

// Explicit instantiation
INSTANTIATE_LINE(track_muon_mva_line::track_muon_mva_line_t, track_muon_mva_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned>
track_muon_mva_line::track_muon_mva_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto track = event_tracks.particle(i);

  return std::forward_as_tuple(track, event_number);
}
__device__ bool track_muon_mva_line::track_muon_mva_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> input)
{
  const auto& track = std::get<0>(input);
  const auto& event_number = std::get<1>(input);
  if (!track.is_muon()) {
    return false;
  }

  const auto ptShift = (track.state().pt() - properties.alpha) / Allen::Units::GeV;
  const auto maxPt_GeV = properties.maxPt / Allen::Units::GeV;
  const auto minPt_GeV = properties.minPt / Allen::Units::GeV;
  const auto ipChi2 = track.ip_chi2();
  const auto minBPVz = properties.minBPVz;
  const auto chi2corr = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + track.get_index()];

  const auto nn = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + track.get_index()];
  bool muonid_bool = false;
  if (properties.useNN) {
    muonid_bool = nn > properties.minMuonNN;
  }
  else {
    muonid_bool = chi2corr < properties.maxChi2Muon;
  }
  const bool decision =
    muonid_bool && track.state().chi2() / track.state().ndof() < properties.maxChi2Ndof &&
    ((ptShift > maxPt_GeV && ipChi2 > properties.minIPChi2) ||
     (ptShift > minPt_GeV && ptShift < maxPt_GeV &&
      logf(ipChi2) > properties.param1 / ((ptShift - properties.param2) * (ptShift - properties.param2)) +
                       properties.param3 / maxPt_GeV * (maxPt_GeV - ptShift) + logf(properties.minIPChi2))) &&
    track.pv().position.z >= minBPVz;

  return decision;
}

__device__ bool track_muon_mva_line::track_muon_mva_line_t::fill_tuples(
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
