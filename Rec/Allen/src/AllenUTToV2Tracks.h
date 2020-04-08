
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
#ifndef ALLENTOUTTRACKS_H
#define ALLENTOUTTRACKS_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"

class AllenUTToV2Tracks final
  : public Gaudi::Functional::Transformer<std::vector<LHCb::Event::v2::Track>(const HostBuffers&)> {
public:
  /// Standard constructor
  AllenUTToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(const HostBuffers&) const override;

private:
};

#endif
