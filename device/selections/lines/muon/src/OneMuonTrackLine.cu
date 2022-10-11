/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "OneMuonTrackLine.cuh"

// Explicit instantiation of the line
INSTANTIATE_LINE(one_muon_track_line::one_muon_track_line_t, one_muon_track_line::Parameters)

void one_muon_track_line::one_muon_track_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, runtime_options, constants, host_buffers);
}
// Selection function
__device__ bool one_muon_track_line::one_muon_track_line_t::select(
  const Parameters& parameters,
  std::tuple<const MuonTrack> input)
{
  const auto& muon_track = std::get<0>(input);
  const bool decision = muon_track.chi2x() < parameters.max_chi2x && muon_track.chi2y() < parameters.max_chi2y;

  return decision;
}
