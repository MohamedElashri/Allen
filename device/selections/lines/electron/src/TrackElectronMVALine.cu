/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "TrackElectronMVALine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(track_electron_mva_line::track_electron_mva_line_t, track_electron_mva_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float>
track_electron_mva_line::track_electron_mva_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(parameters.dev_multi_event_tracks[0].particle_container(event_number));
  const auto track = event_tracks.particle(i);

  const bool is_electron = track.is_electron();

  const float corrected_pt = parameters.dev_brem_corrected_pt[i + parameters.dev_track_offsets[event_number]];

  return std::forward_as_tuple(track, is_electron, corrected_pt);
}

__device__ bool track_electron_mva_line::track_electron_mva_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float> input)
{
  const auto& track = std::get<0>(input);
  const auto& is_electron = std::get<1>(input);
  const auto& corrected_pt = std::get<2>(input);

  // Electron ID
  if (!is_electron) {
    return false;
  }

  const auto ptShift = (corrected_pt - parameters.alpha);
  const auto maxPt = parameters.maxPt;
  const auto minIPChi2 = parameters.minIPChi2;
  const auto trackIPChi2 = track.ip_chi2();

  const bool decision =
    track.state().chi2() / track.state().ndof() < parameters.maxChi2Ndof &&
    ((ptShift > maxPt && trackIPChi2 > minIPChi2) ||
     (ptShift > parameters.minPt && ptShift < maxPt &&
      logf(trackIPChi2) > parameters.param1 / ((ptShift - parameters.param2) * (ptShift - parameters.param2)) +
                            (parameters.param3 / maxPt) * (maxPt - ptShift) + logf(minIPChi2)));
  return decision;
}
