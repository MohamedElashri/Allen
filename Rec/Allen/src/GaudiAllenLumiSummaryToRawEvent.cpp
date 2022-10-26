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

#include "GaudiAllenLumiSummaryToRawEvent.h"

#include <HltConstants.cuh>

// LHCb
#include "Kernel/STLExtensions.h"

DECLARE_COMPONENT(GaudiAllenLumiSummaryToRawEvent)

GaudiAllenLumiSummaryToRawEvent::GaudiAllenLumiSummaryToRawEvent(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_lumi_summaries", ""}, KeyValue {"allen_lumi_summary_offsets", ""}},
    // Outputs
    {KeyValue {"OutputLumiSummary", "Allen/Out/LumiSummary"}})
{}

LHCb::RawEvent GaudiAllenLumiSummaryToRawEvent::operator()(
  const std::vector<unsigned>& allen_lumi_summaries,
  const std::vector<unsigned>& allen_lumi_summary_offsets) const
{

  LHCb::RawEvent raw_event;
  auto lumi_summaries = LHCb::make_span(&allen_lumi_summaries[0], allen_lumi_summary_offsets[1]);
  raw_event.addBank(Hlt1::Constants::sourceID, LHCb::RawBank::HltLumiSummary, 2u, lumi_summaries);

  return raw_event;
}
