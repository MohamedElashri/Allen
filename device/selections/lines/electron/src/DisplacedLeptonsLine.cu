/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DisplacedLeptonsLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(displaced_leptons_line::displaced_leptons_line_t, displaced_leptons_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*>
displaced_leptons_line::displaced_leptons_line_t::get_input(const Parameters& parameters, const unsigned event_number)
{
  const auto event_tracks = parameters.dev_tracks[event_number];

  const unsigned N_tracks = parameters.dev_track_offsets[event_number + 1] - parameters.dev_track_offsets[event_number];

  const bool* are_electrons = parameters.dev_track_isElectron + parameters.dev_track_offsets[event_number];

  const float* brem_corrected_pts = parameters.dev_brem_corrected_pt + parameters.dev_track_offsets[event_number];

  return std::forward_as_tuple(event_tracks, N_tracks, are_electrons, brem_corrected_pts);
}

__device__ bool displaced_leptons_line::displaced_leptons_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*> input)
{
  const auto tracks = std::get<0>(input);
  const unsigned N_tracks = std::get<1>(input);
  const bool* are_electrons = std::get<2>(input);
  const float* brem_corrected_pts = std::get<3>(input);

  unsigned N_good_leptons {0};
  for (unsigned i {0}; i < N_tracks; ++i) {
    const auto track = tracks.particle(i);

    if (
      (track.is_electron() && track.ip_chi2() > parameters.min_ipchi2 && brem_corrected_pts[i] > parameters.min_pt) ||
      (track.is_muon() && track.ip_chi2() > parameters.min_ipchi2 && track.pt() > parameters.min_pt))
      N_good_leptons += 1;
  }
  return N_good_leptons > 1;
}
