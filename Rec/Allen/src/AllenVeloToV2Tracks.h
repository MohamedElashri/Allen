/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef ALLENTOVELOTRACKS_H
#define ALLENTOVELOTRACKS_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"
#include "VeloConsolidated.cuh"

class AllenVeloToV2Tracks final
  : public Gaudi::Functional::Transformer<std::vector<LHCb::Event::v2::Track>(const HostBuffers&)> {
public:
  /// Standard constructor
  AllenVeloToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(const HostBuffers&) const override;

private:
  Gaudi::Property<float> m_ptVelo {this, "ptVelo", 400 * Gaudi::Units::MeV, "Default pT for Velo tracks"};
};

#endif
