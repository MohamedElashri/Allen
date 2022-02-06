/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DisplacedDielectronLine.cuh"

INSTANTIATE_LINE(displaced_dielectron_line::displaced_dielectron_line_t, displaced_dielectron_line::Parameters)

__device__ std::tuple<const VertexFit::TrackMVAVertex&, const bool, const float>
displaced_dielectron_line::displaced_dielectron_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const VertexFit::TrackMVAVertex* event_vertices = parameters.dev_svs + parameters.dev_sv_offsets[event_number];
  const auto& vertex = event_vertices[i];

  const bool is_electron_1 = parameters.dev_track_isElectron[vertex.trk1 + parameters.dev_track_offsets[event_number]];
  const bool is_electron_2 = parameters.dev_track_isElectron[vertex.trk2 + parameters.dev_track_offsets[event_number]];
  const bool is_dielectron = is_electron_1 && is_electron_2;

  const float brem_corrected_minpt = min(
    parameters.dev_brem_corrected_pt[vertex.trk1 + parameters.dev_track_offsets[event_number]],
    parameters.dev_brem_corrected_pt[vertex.trk2 + parameters.dev_track_offsets[event_number]]);

  return std::forward_as_tuple(vertex, is_dielectron, brem_corrected_minpt);
}

__device__ bool displaced_dielectron_line::displaced_dielectron_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&, const bool, const float> input)
{
  const VertexFit::TrackMVAVertex& vertex = std::get<0>(input);
  const bool is_dielectron = std::get<1>(input);
  const float brem_corrected_minpt = std::get<2>(input);

  // Electron ID
  if (!is_dielectron) {
    return false;
  }

  bool decision = vertex.minipchi2 > parameters.minIPChi2 && vertex.doca < parameters.maxDOCA &&
                  brem_corrected_minpt > parameters.minPT && vertex.chi2 < parameters.maxVtxChi2;

  return decision;
}
