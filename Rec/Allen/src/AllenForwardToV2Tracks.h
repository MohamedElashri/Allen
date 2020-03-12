
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
#ifndef ALLENFORWARDTOV2TRACKS_H
#define ALLENFORWARDTOV2TRACKS_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"
#include "ParKalmanDefinitions.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"

#include <AIDA/IHistogram1D.h>

class AllenForwardToV2Tracks final
  : public Gaudi::Functional::MultiTransformer<
      std::tuple<std::vector<LHCb::Event::v2::Track>, std::vector<LHCb::Event::v2::Track>>(const HostBuffers&),
      Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {

public:
  /// Standard constructor
  AllenForwardToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::tuple<std::vector<LHCb::Event::v2::Track>, std::vector<LHCb::Event::v2::Track>> operator()(
    const HostBuffers&) const override;

private:
  const std::array<float, 5> default_covarianceValues {4.0, 400.0, 4.e-6, 1.e-4, 0.1};
  Gaudi::Property<std::array<float, 5>> m_covarianceValues {this, "covarianceValues", default_covarianceValues};

  std::unordered_map<std::string, AIDA::IHistogram1D*> m_histos;
};

#endif
