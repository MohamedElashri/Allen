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

LHCb::RawEvent AllenSelReportsToTES::operator()(const HostBuffers& host_buffers) const
{

  LHCb::RawEvent raw_event;
  // TODO: get these hard coded numbers from somewhere else... should be defined in one location only!
  constexpr auto hlt1SourceID = (1u << 13);
  constexpr auto sel_rep_version = 9u, dec_rep_version = 2u;
  raw_event.addBank(hlt1SourceID, LHCb::RawBank::HltSelReports, sel_rep_version, host_buffers.host_sel_reports);
  raw_event.addBank(hlt1SourceID, LHCb::RawBank::HltDecReports, dec_rep_version, host_buffers.host_dec_reports);

  return raw_event;
}
