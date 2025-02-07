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
#include "LowPtMuonLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(low_pt_muon_line::low_pt_muon_line_t, low_pt_muon_line::Parameters)

__device__ bool low_pt_muon_line::low_pt_muon_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticle> input)
{
  const auto track = std::get<0>(input);
  return track.is_muon() && track.ip() >= properties.minIP && track.ip_chi2() >= properties.minIPChi2 &&
         track.state().pt() >= properties.minPt &&
         track.state().chi2() / track.state().ndof() <= properties.maxChi2Ndof &&
         track.pv().position.z >= properties.minBPVz;
}
