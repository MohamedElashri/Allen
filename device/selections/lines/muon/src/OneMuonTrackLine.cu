/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "OneMuonTrackLine.cuh"

// Explicit instantiation of the line
INSTANTIATE_LINE(one_muon_track_line::one_muon_track_line_t, one_muon_track_line::Parameters)

// Selection function
__device__ bool one_muon_track_line::one_muon_track_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const MuonTrack> input)
{
  const auto& muon_track = std::get<0>(input);
  const bool decision = muon_track.chi2x() < properties.max_chi2x && muon_track.chi2y() < properties.max_chi2y;

  return decision;
}
