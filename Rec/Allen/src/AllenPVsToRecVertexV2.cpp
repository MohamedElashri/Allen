/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

/**
 * Convert PV::Vertex into LHCb::Event::v2::RecVertex
 *
 * author Dorothea vom Bruch
 *
 */

#include "AllenPVsToRecVertexV2.h"

DECLARE_COMPONENT(AllenPVsToRecVertexV2)

AllenPVsToRecVertexV2::AllenPVsToRecVertexV2(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"},
     KeyValue {"BeamSpotLocation", "AlgorithmSpecific-" + name + "-beamspot"}},
    // Outputs
    {KeyValue {"OutputPVs", "Allen/PVs/v2/RecVertex"}})
{}

StatusCode AllenPVsToRecVertexV2::initialize()
{
  using namespace ConditionHolders;
  auto sc = Transformer::initialize().andThen(
    [&] { addConditionDerivation<Beamline_t(Condition const&)>({beamSpotCond}, inputLocation<Beamline_t>()); });

  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

LHCb::Event::v2::RecVertices AllenPVsToRecVertexV2::operator()(
  const HostBuffers& host_buffers,
  const ConditionHolders::Beamline_t& beamline) const
{

  const unsigned i_event = 0;
  const unsigned n_pvs = host_buffers.host_number_of_multivertex[i_event];

  if (msgLevel(MSG::DEBUG)) debug() << "Number of PVs to convert = " << n_pvs << endmsg;

  LHCb::Event::v2::RecVertices recvertexcontainer;
  recvertexcontainer.reserve(n_pvs);
  const auto maxVertexRho2 = m_maxVertexRho.value() * m_maxVertexRho.value();

  for (unsigned int i = 0; i < n_pvs; i++) {
    const PV::Vertex& vertex = host_buffers.host_reconstructed_multi_pvs[i_event * PatPV::max_number_vertices + i];

    const auto beamlinedx = vertex.position.x - beamline.X;
    const auto beamlinedy = vertex.position.y - beamline.Y;
    const auto beamlinerho2 = beamlinedx * beamlinedx + beamlinedy * beamlinedy;
    if (vertex.nTracks >= m_minNumTracksPerVertex && beamlinerho2 < maxVertexRho2) { // already checked in Allen PV
                                                                                     // finder
      Gaudi::SymMatrix3x3 poscov;
      poscov(0, 0) = vertex.cov00;
      poscov(1, 0) = vertex.cov10;
      poscov(1, 1) = vertex.cov11;
      poscov(2, 0) = vertex.cov20;
      poscov(2, 1) = vertex.cov21;
      poscov(2, 2) = vertex.cov22;
      Gaudi::XYZPoint position {vertex.position.x, vertex.position.y, vertex.position.z};
      auto& recvertex = recvertexcontainer.emplace_back(
        position, poscov, LHCb::Event::v2::Track::Chi2PerDoF {vertex.chi2 / vertex.ndof, vertex.ndof});
      recvertex.setTechnique(LHCb::Event::v2::RecVertex::RecVertexType::Primary);
      const int nTracks = int(std::roundf(vertex.nTracks));
      recvertex.reserve(nTracks);
      for (int i = 0; i < nTracks; i++) {
        recvertex.addToTracks(nullptr, 0.f); // TODO: save weight for every track if needed
      }
    }
  }

  m_nbPVsCounter += recvertexcontainer.size();
  return recvertexcontainer;
}
