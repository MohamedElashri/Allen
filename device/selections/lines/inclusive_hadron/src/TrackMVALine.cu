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
#include "TrackMVALine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(track_mva_line::track_mva_line_t, track_mva_line::Parameters)

__device__ bool track_mva_line::track_mva_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto track = std::get<0>(input);
  const auto ptShift = (track.state().pt() - properties.alpha);
  const bool decision =
    track.state().chi2() / track.state().ndof() < properties.maxChi2Ndof &&
    ((ptShift > properties.maxPt && track.has_pv() && track.ip_chi2() > properties.minIPChi2) ||
     (ptShift > properties.minPt && ptShift < properties.maxPt &&
      logf(track.ip_chi2()) > properties.param1 / ((ptShift - properties.param2) * (ptShift - properties.param2)) +
                                (properties.param3 / properties.maxPt) * (properties.maxPt - ptShift) +
                                logf(properties.minIPChi2))) &&
    track.pv().position.z > properties.minBPVz && track.track().ghost_probability() < properties.maxGhostProb;

  return decision;
}

__device__ void track_mva_line::track_mva_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle> input,
  unsigned,
  bool sel)
{
  const auto track = std::get<0>(input);
  if (sel) {
    properties.histogram_ghost_prob.increment(track.track().ghost_probability());
    properties.histogram_ip_x.increment(track.ip_x());
    properties.histogram_ip_y.increment(track.ip_y());
  }
}

__device__ bool track_mva_line::track_mva_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::BasicParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& track = std::get<0>(input);
    parameters.ipchi2[index] = track.ip_chi2();
    parameters.pt[index] = track.state().pt();
    parameters.ghostProb[index] = track.track().ghost_probability();
  }
  return sel;
}
