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
  const Parameters& parameters,
  const DeviceAccumulators&,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto track = std::get<0>(input);
  const auto ptShift = (track.state().pt() - parameters.alpha);
  const bool decision =
    track.state().chi2() / track.state().ndof() < parameters.maxChi2Ndof &&
    ((ptShift > parameters.maxPt && track.has_pv() && track.ip_chi2() > parameters.minIPChi2) ||
     (ptShift > parameters.minPt && ptShift < parameters.maxPt &&
      logf(track.ip_chi2()) > parameters.param1 / ((ptShift - parameters.param2) * (ptShift - parameters.param2)) +
                                (parameters.param3 / parameters.maxPt) * (parameters.maxPt - ptShift) +
                                logf(parameters.minIPChi2))) &&
    track.pv().position.z > parameters.minBPVz && track.track().ghost_probability() < parameters.maxGhostProb;

  return decision;
}

__device__ void track_mva_line::track_mva_line_t::monitor(
  const Parameters&,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::BasicParticle> input,
  unsigned,
  bool sel)
{
  const auto track = std::get<0>(input);
  if (sel) {
    accumulators.histogram_ghost_prob.increment(track.track().ghost_probability());
    accumulators.histogram_ip_x.increment(track.ip_x());
    accumulators.histogram_ip_y.increment(track.ip_y());
  }
}

__device__ void track_mva_line::track_mva_line_t::fill_tuples(
  const Parameters& parameters,
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
}
