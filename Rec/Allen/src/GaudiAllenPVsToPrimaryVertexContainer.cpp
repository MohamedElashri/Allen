/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

/**
 * Convert PV::Vertex into LHCb::Event::PV::PrimaryVertexContainer
 *
 * author Dorothea vom Bruch and Wouter Hulsbergen
 *
 */

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "Gaudi/Accumulators.h"

// LHCb
#include "Event/PrimaryVertices.h"

// Allen
#include "Logger.h"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"

using Vertices = LHCb::Event::PV::PrimaryVertexContainer;

class GaudiAllenPVsToPrimaryVertexContainer final
  : public Gaudi::Functional::Transformer<Vertices(const std::vector<unsigned>&, const std::vector<PV::Vertex>&)> {
public:
  /// Standard constructor
  GaudiAllenPVsToPrimaryVertexContainer(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  Vertices operator()(const std::vector<unsigned>&, const std::vector<PV::Vertex>&) const override;

private:
  mutable Gaudi::Accumulators::SummingCounter<unsigned int> m_nbPVsCounter {this, "Nb PVs"};
};

DECLARE_COMPONENT(GaudiAllenPVsToPrimaryVertexContainer)

GaudiAllenPVsToPrimaryVertexContainer::GaudiAllenPVsToPrimaryVertexContainer(
  const std::string& name,
  ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"number_of_multivertex", ""}, KeyValue {"reconstructed_multi_pvs", ""}},
    // Outputs
    {KeyValue {"OutputPVs", "Allen/PVs/PrimaryVertices"}})
{}

StatusCode GaudiAllenPVsToPrimaryVertexContainer::initialize()
{
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;
  return StatusCode::SUCCESS;
}

Vertices GaudiAllenPVsToPrimaryVertexContainer::operator()(
  const std::vector<unsigned>& number_of_multivertex,
  const std::vector<PV::Vertex>& reconstructed_multi_pvs) const
{

  const unsigned i_event = 0;
  const unsigned n_pvs = number_of_multivertex[i_event];

  if (msgLevel(MSG::DEBUG)) debug() << "Number of PVs to convert = " << n_pvs << endmsg;

  Vertices pvcontainer;
  auto& vertices = pvcontainer.vertices;
  vertices.reserve(n_pvs);

  for (unsigned int i = 0; i < n_pvs; i++) {
    const PV::Vertex& vertex = reconstructed_multi_pvs[i_event * PatPV::max_number_vertices + i];

    Gaudi::SymMatrix3x3 poscov;
    poscov(0, 0) = vertex.cov00;
    poscov(1, 0) = vertex.cov10;
    poscov(1, 1) = vertex.cov11;
    poscov(2, 0) = vertex.cov20;
    poscov(2, 1) = vertex.cov21;
    poscov(2, 2) = vertex.cov22;
    auto& recvertex = vertices.emplace_back(Gaudi::XYZPoint {vertex.position.x, vertex.position.y, vertex.position.z});
    recvertex.setCovMatrix(poscov);
    recvertex.setChi2(vertex.chi2);
    // vertex.nTracks contains the sum of weights from Allen TBLV. To convert it to Number of Degrees of Freedom ->
    // Nubmer of Tracks we can use linear parametrisation described here
    // https://indico.cern.ch/event/1370630/contributions/5849852. nTrack = (nDoF+3)/2
    recvertex.setNDoF(std::lround(2 * (1 + 1.58 * vertex.nTracks) - 3));
  }

  m_nbPVsCounter += vertices.size();
  return pvcontainer;
}
