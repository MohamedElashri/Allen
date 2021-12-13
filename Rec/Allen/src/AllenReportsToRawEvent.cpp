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
#ifndef ALLENREPORTSTORAWEVENT_H
#define ALLENREPORTSTORAWEVENT_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/RawEvent.h"
#include "Kernel/STLExtensions.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"

class AllenReportsToRawEvent final : public Gaudi::Functional::Transformer<LHCb::RawEvent(const HostBuffers&)> {
public:
  // Standard constructor
  AllenReportsToRawEvent(const std::string& name, ISvcLocator* pSvcLocator);

  // Algorithm execution
  LHCb::RawEvent operator()(const HostBuffers&) const override;

private:
};

#endif

DECLARE_COMPONENT(AllenReportsToRawEvent)

AllenReportsToRawEvent::AllenReportsToRawEvent(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputRawReports", "Allen/Out/RawReports"}})
{}

LHCb::RawEvent AllenReportsToRawEvent::operator()(const HostBuffers& host_buffers) const
{

  LHCb::RawEvent raw_event;
  // TODO: get these hard coded numbers from somewhere else... should be defined in one location only!
  constexpr auto hlt1SourceID = (1u << 13);
  constexpr auto sel_rep_version = 9u, dec_rep_version = 2u;
  auto dec_reports = LHCb::make_span(
    &host_buffers.host_dec_reports[0], &host_buffers.host_dec_reports[host_buffers.host_number_of_lines + 1] + 1);
  auto sel_reports = LHCb::make_span(host_buffers.host_sel_reports.data(), host_buffers.host_sel_report_offsets[1]);
  raw_event.addBank(hlt1SourceID, LHCb::RawBank::HltSelReports, sel_rep_version, sel_reports);
  raw_event.addBank(hlt1SourceID, LHCb::RawBank::HltDecReports, dec_rep_version, dec_reports);

  return raw_event;
}
