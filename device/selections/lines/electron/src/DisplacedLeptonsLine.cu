/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*> input)
{
  const auto tracks = std::get<0>(input);
  const unsigned N_tracks = std::get<1>(input);
  const float* brem_corrected_pts = std::get<3>(input);

  unsigned N_good_leptons {0};
  for (unsigned i {0}; i < N_tracks; ++i) {
    const auto track = tracks.particle(i);

    if (((track.is_electron() && track.ip_chi2() > parameters.min_ipchi2 &&
          brem_corrected_pts[i] > parameters.min_pt) ||
         (track.is_muon() && track.ip_chi2() > parameters.min_ipchi2 && track.state().pt() > parameters.min_pt))) {
      if (!track.has_pv() || (track.has_pv() && track.pv().position.z < parameters.minBPVz)) N_good_leptons += 1;
    }
  }
  return N_good_leptons > 1;
}
