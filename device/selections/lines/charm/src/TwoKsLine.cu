/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TwoKsLine.cuh"

INSTANTIATE_LINE(two_ks_line::two_ks_line_t, two_ks_line::Parameters)

// Offset function
__device__ unsigned two_ks_line::two_ks_line_t::offset(const Parameters& parameters, const unsigned event_number)
{
  return parameters.dev_sv_offsets[event_number];
}

unsigned two_ks_line::two_ks_line_t::get_decisions_size(ArgumentReferences<Parameters>& arguments)
{
  return first<typename Parameters::host_number_of_svs_t>(arguments);
}

__device__ std::tuple<const VertexFit::TrackMVAVertex&, const unsigned, const unsigned>
two_ks_line::two_ks_line_t::get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
{
  const VertexFit::TrackMVAVertex* event_vertices = parameters.dev_svs + parameters.dev_sv_offsets[event_number];
  const auto& vertex = event_vertices[i];
  return std::forward_as_tuple(vertex, event_number, i);
}

__device__ bool two_ks_line::two_ks_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&, const unsigned, const unsigned> input)
{
  // Unpack the tuple.
  const auto& vertex1 = std::get<0>(input);
  const auto& event_number = std::get<1>(input);
  const auto& vertex1_id = std::get<2>(input);

  const VertexFit::TrackMVAVertex* event_vertices = parameters.dev_svs + parameters.dev_sv_offsets[event_number];
  unsigned n_svs = parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];
  for (unsigned i = vertex1_id + 1; i < n_svs; i++) {
    const auto& vertex2 = event_vertices[i];

    // Return false if the vertices have a common track.
    // Make this selection first as it is will initially reject the
    // largest amount of combinations.
    if (
      vertex1.trk1 == vertex2.trk1 || vertex1.trk1 == vertex2.trk2 || vertex1.trk2 == vertex2.trk2 ||
      vertex1.trk2 == vertex2.trk1) {
      continue;
    }

    // Return false if vertex fit failed for either vertex.
    if (vertex1.chi2 < 0 || vertex2.chi2 < 0) {
      continue;
    }

    const bool decision =
      vertex1.chi2 < parameters.maxVertexChi2 && vertex1.eta > parameters.minEta_Ks &&
      vertex1.eta < parameters.maxEta_Ks && vertex1.minipchi2 > parameters.minTrackIPChi2_Ks &&
		       vertex1.m(Allen::mPi, Allen::mPi) > parameters.minM_Ks && vertex1.m(Allen::mPi, Allen::mPi) < parameters.maxM_Ks &&
      vertex1.pt() > parameters.minComboPt_Ks && vertex1.cos > parameters.minCosOpening &&
      vertex1.dira > parameters.minCosDira && vertex1.p1 > parameters.minTrackP_piKs &&
      vertex1.p2 > parameters.minTrackP_piKs && vertex1.ip1 * vertex1.ip2 / vertex1.vertex_ip > parameters.min_combip &&
      vertex1.minpt > parameters.minTrackPt_piKs && vertex2.chi2 < parameters.maxVertexChi2 &&
      vertex2.eta > parameters.minEta_Ks && vertex2.eta < parameters.maxEta_Ks &&
							  vertex2.minipchi2 > parameters.minTrackIPChi2_Ks && vertex2.m(Allen::mPi, Allen::mPi) > parameters.minM_Ks &&
      vertex2.m(Allen::mPi, Allen::mPi) < parameters.maxM_Ks && vertex2.pt() > parameters.minComboPt_Ks &&
      vertex2.cos > parameters.minCosOpening && vertex2.dira > parameters.minCosDira &&
      vertex2.p1 > parameters.minTrackP_piKs && vertex2.p2 > parameters.minTrackP_piKs &&
      vertex2.ip1 * vertex2.ip2 / vertex2.vertex_ip > parameters.min_combip &&
      vertex2.minpt > parameters.minTrackPt_piKs;

    if (decision) {
      return decision;
    }
  }

  return false;
}
