/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef ALLENDECREPORTSTOTES_H
#define ALLENDECREPORTSTOTES_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/RawEvent.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"

class AllenDecReportsToTES final : public Gaudi::Functional::Transformer<LHCb::RawEvent(const HostBuffers&)> {
public:
  /// Standard constructor
  AllenDecReportsToTES(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  LHCb::RawEvent operator()(const HostBuffers&) const override;

private:
};

#endif
