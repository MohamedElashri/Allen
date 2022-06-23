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
/**
 * Convert VertexFit::TrackMVAVertex into LHCb::Event::v2::RecVertex
 *
 * author Tom Boettcher
 *
 */

#include <sstream>

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track_v2.h"
#include "Event/RecVertex_v2.h"

// Allen
#include "Logger.h"
#include "VertexDefinitions.cuh"
/**
 * Convert VertexFit::TrackMVAVertex into LHCb::Event::v2::RecVertex
 *
 * author Tom Boettcher
 *
 */

class GaudiAllenSVsToRecVertexV2 final : public Gaudi::Functional::Transformer<LHCb::Event::v2::RecVertices(
                                           const std::vector<unsigned>&,
                                           const std::vector<unsigned>&,
                                           const std::vector<VertexFit::TrackMVAVertex>&,
                                           const std::vector<LHCb::Event::v2::Track>&)> {
public:
  // Standard constructor
  GaudiAllenSVsToRecVertexV2(const std::string& name, ISvcLocator* pSvcLocator);

  // Initialization
  StatusCode initialize() override;

  // Algorithm execution
  LHCb::Event::v2::RecVertices operator()(
    const std::vector<unsigned>&,
    const std::vector<unsigned>&,
    const std::vector<VertexFit::TrackMVAVertex>&,
    const std::vector<LHCb::Event::v2::Track>&) const override;
};

DECLARE_COMPONENT(GaudiAllenSVsToRecVertexV2)

GaudiAllenSVsToRecVertexV2::GaudiAllenSVsToRecVertexV2(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_atomics_scifi", ""},
     KeyValue {"allen_sv_offsets", ""},
     KeyValue {"allen_secondary_vertices", ""},
     KeyValue {"InputTracks", "Allen/Out/ForwardTracks"}},
    // Outputs
    {KeyValue {"OutputSVs", "Allen/Out/RecVertex"}})
{}

StatusCode GaudiAllenSVsToRecVertexV2::initialize()
{
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;
  return StatusCode::SUCCESS;
}

LHCb::Event::v2::RecVertices GaudiAllenSVsToRecVertexV2::operator()(
  const std::vector<unsigned>& allen_atomics_scifi,
  const std::vector<unsigned>& allen_sv_offsets,
  const std::vector<VertexFit::TrackMVAVertex>& allen_secondary_vertices,
  const std::vector<LHCb::Event::v2::Track>& tracks) const
{
  // Check number of tracks
  const unsigned i_event = 0;
  const unsigned ev_n_trk = allen_atomics_scifi[i_event + 1] - allen_atomics_scifi[i_event];
  if (ev_n_trk != tracks.size()) {
    std::ostringstream oss;
    oss << "Mismatch in number of input tracks, needed " << ev_n_trk << " but the provided track container has "
        << tracks.size() << "\n";
    oss << "Check the data passsed to  InputTracks";
    throw GaudiException(oss.str(), this->name(), StatusCode::FAILURE);
  }

  const unsigned sv_offset = allen_sv_offsets[i_event];
  const unsigned n_svs = allen_sv_offsets[i_event + 1] - sv_offset;

  if (msgLevel(MSG::DEBUG)) {
    debug() << "Number of SVs to convert = " << n_svs << endmsg;
    debug() << "Number of input tracks = " << tracks.size() << endmsg;
  }

  LHCb::Event::v2::RecVertices sv_container;
  sv_container.reserve(n_svs);

  for (unsigned int i = 0; i < n_svs; i++) {
    if (msgLevel(MSG::DEBUG)) debug() << "  Processing SV " << i << endmsg;
    const VertexFit::TrackMVAVertex& sv = allen_secondary_vertices[sv_offset + i];
    Gaudi::SymMatrix3x3 poscov;
    poscov(0, 0) = sv.cov00;
    poscov(1, 0) = sv.cov10;
    poscov(1, 1) = sv.cov11;
    poscov(2, 0) = sv.cov20;
    poscov(2, 1) = sv.cov21;
    poscov(2, 2) = sv.cov22;
    Gaudi::XYZPoint position {sv.x, sv.y, sv.z};
    auto& new_sv = sv_container.emplace_back(position, poscov, LHCb::Event::v2::Track::Chi2PerDoF {sv.chi2 / 2, 2});
    const unsigned i_trackA = sv.trk1;
    const unsigned i_trackB = sv.trk2;
    if (msgLevel(MSG::DEBUG)) debug() << "    Track indexes " << i_trackA << ", " << i_trackB << endmsg;
    new_sv.addToTracks(&tracks[i_trackA], 0.f);
    new_sv.addToTracks(&tracks[i_trackB], 0.f);
  }

  return sv_container;
}
