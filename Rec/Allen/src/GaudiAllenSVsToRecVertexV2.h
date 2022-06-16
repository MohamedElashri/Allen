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
#pragma once

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
