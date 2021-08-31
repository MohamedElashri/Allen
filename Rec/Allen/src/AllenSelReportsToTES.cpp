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
#ifndef ALLENSELREPORTSTOTES_H
#define ALLENSELREPORTSTOTES_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/RawEvent.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"

class AllenSelReportsToTES final : public Gaudi::Functional::Transformer<LHCb::RawEvent(const HostBuffers&)> {
public:
  // Standard constructor
  AllenSelReportsToTES(const std::string& name, ISvcLocator* pSvcLocator);

  // initialization
  StatusCode initialize() override;

  // Algorithm execution
  LHCb::RawEvent operator()(const HostBuffers&) const override;

private:
};

#endif

DECLARE_COMPONENT(AllenSelReportsToTES)

AllenSelReportsToTES::AllenSelReportsToTES(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputSelReports", "Allen/Out/RawSelReports"}})
{}

StatusCode AllenSelReportsToTES::initialize()
{
  auto sc = Transformer::initialize();

  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

LHCb::RawEvent AllenSelReportsToTES::operator()(const HostBuffers& host_buffers) const
{

  std::vector<unsigned int> sel_report;
  unsigned selrep_size = host_buffers.host_sel_reports[0];
  for (unsigned i = 0; i < selrep_size; i++) {
    sel_report.push_back(host_buffers.host_sel_reports[i]);
  }
  LHCb::RawEvent raw_event;
  raw_event.addBank(int(1 << 13), LHCb::RawBank::HltSelReports, 9u, sel_report);

  return raw_event;
}
