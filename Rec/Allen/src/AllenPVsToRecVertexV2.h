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
#ifndef ALLENPVSTORECVERTEXV2_H
#define ALLENPVSTORECVERTEXV2_H

// Gaudi
#include "GaudiAlg/Transformer.h"

// LHCb
#include "Event/Track.h"
#include "Event/RecVertex_v2.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"

class AllenPVsToRecVertexV2 final
  : public Gaudi::Functional::Transformer<LHCb::Event::v2::RecVertices(const HostBuffers&)> {
public:
  /// Standard constructor
  AllenPVsToRecVertexV2(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  LHCb::Event::v2::RecVertices operator()(const HostBuffers&) const override;

private:
  mutable Gaudi::Accumulators::SummingCounter<unsigned int> m_nbPVsCounter {this, "Nb PVs"};
};

#endif
