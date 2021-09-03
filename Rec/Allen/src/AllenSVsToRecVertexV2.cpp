/**
 * Convert VertexFit::TrackMVAVertex into LHCb::Event::v2::RecVertex
 *
 * author Tom Boettcher
 *
 */
#ifndef ALLENSVSTORECVERTEXV2_H
#define ALLENSVSTORECVERTEXV2_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"
#include "Event/RecVertex_v2.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"
#include "VertexDefinitions.cuh"

class AllenSVsToRecVertexV2 final
  : public Gaudi::Functional::Transformer<LHCb::Event::v2::RecVertices(const HostBuffers&)> {
public:
  // Standard constructor
  AllenSVsToRecVertexV2(const std::string& name, ISvcLocator* pSvcLocator);

  // Initialization
  StatusCode initialize() override;

  // Algorithm execution
  LHCb::Event::v2::RecVertices operator()(const HostBuffers&) const override;
};

#endif

DECLARE_COMPONENT(AllenSVsToRecVertexV2)

AllenSVsToRecVertexV2::AllenSVsToRecVertexV2(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"},
     KeyValue {"OutputTracks", "Allen/Out/ForwardTracks"}},
    // Outputs
    {KeyValue {"OutputSVs", "Allen/Out/RecVertex"}})
{}

StatusCode AllenSVsToRecVertexV2::initialize()
{
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;
  return StatusCode::SUCCESS;
}

LHCb::Event::v2::RecVertices AllenSVsToRecVertexV2::operator()(
    const HostBuffers& host_buffers, 
    const std::vector<LHCb::Event::v2::Track>& tracks) const
{
    const unsigned i_event = 0;
    const unsigned n_svs = host_buffers.host_number_of_svs[i_event];

    LHCb::Event::v2::RecVertices sv_container;
    sv_container.reserve(n_pvs);

    for (unsigned int i = 0; i < n_svs; i++) {
        const VertexFit::TrackMVAVertex& sv = host_buffers.host_consolidated_svs[i];
        Gaudi::SymMatrix3x3 poscov;
        poscov(0, 0) = sv.cov00;
        poscov(1, 0) = sv.cov10;
        poscov(1, 1) = sv.cov11;
        poscov(2, 0) = sv.cov20;
        poscov(2, 1) = sv.cov21;
        poscov(2, 2) = sv.cov22;
        Gaudi::XYZPoint position {sv.x, sv.y, sv.z};
        auto& new_sv = sv_container.emplace_back(    
            position, poscov, LHCb::Event::v2::Track::Chi2PerDoF {vertex.chi2/2, 2});
        const unsigned i_trackA = sv.trk1;
        const unsigned i_trackB = sv.trk2;
        new_sv.addToTracks(&tracks[i_trackA], 0.f);
        new_sv.addToTracks(&tracks[i_trackB], 0.f);
    }

    return sv_container;

}