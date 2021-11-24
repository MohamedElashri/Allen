/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TwoTrackKsLine.cuh"

INSTANTIATE_LINE(two_track_line_ks::two_track_line_ks_t, two_track_line_ks::Parameters)

__device__ bool two_track_line_ks::two_track_line_ks_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vertex = std::get<0>(input);
  if (vertex.chi2 < 0) {
    return false;
  }

  const bool decision =
    vertex.chi2 < parameters.maxVertexChi2 && vertex.eta > parameters.minEta_Ks && vertex.eta < parameters.maxEta_Ks &&
    vertex.minipchi2 > parameters.minTrackIPChi2_Ks && vertex.m(139.57061, 139.57061) > parameters.minM_Ks &&
    vertex.m(139.57061, 139.57061) < parameters.maxM_Ks && vertex.pt() > parameters.minComboPt_Ks &&
    vertex.cos > parameters.minCosOpening && vertex.dira > parameters.minCosDira &&
    vertex.p1 > parameters.minTrackP_piKs && vertex.p2 > parameters.minTrackP_piKs &&
    vertex.ip1 * vertex.ip2 / vertex.vertex_ip > parameters.min_combip && vertex.minpt > parameters.minTrackPt_piKs;
  return decision;
}
