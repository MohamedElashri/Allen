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
#include "DisplacedLeptonsLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(displaced_leptons_line::displaced_leptons_line_t, displaced_leptons_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*>
displaced_leptons_line::displaced_leptons_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned)
{
  const auto event_tracks = parameters.dev_track_container->container(event_number);
  const unsigned N_tracks = event_tracks.size();
  const bool* are_electrons = parameters.dev_track_isElectron + event_tracks.offset();
  const float* brem_corrected_pts = parameters.dev_brem_corrected_pt + event_tracks.offset();

  return std::forward_as_tuple(event_tracks, N_tracks, are_electrons, brem_corrected_pts);
}

__device__ bool displaced_leptons_line::displaced_leptons_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*> input)
{
  const auto tracks = std::get<0>(input);
  const unsigned N_tracks = std::get<1>(input);
  const float* brem_corrected_pts = std::get<3>(input);

  unsigned N_good_leptons {0};
  for (unsigned i {0}; i < N_tracks; ++i) {
    const auto track = tracks.particle(i);

    if (
      (track.has_pv() && track.ip_chi2() > properties.min_ipchi2 && track.pv().position.z > properties.min_BPVz) &&
      ((track.is_electron() && brem_corrected_pts[i] > properties.min_pt) ||
       (track.is_muon() && track.state().pt() > properties.min_pt))) {
      N_good_leptons += 1;
    }
  }
  return N_good_leptons > 1;
}
