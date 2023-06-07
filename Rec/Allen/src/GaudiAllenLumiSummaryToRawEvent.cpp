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

// Standard
#include <vector>

// Gaudi
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include <LHCbAlgs/Transformer.h>
#include "Kernel/STLExtensions.h"
#include "Event/RawEvent.h"
#include <HltConstants.cuh>

struct GaudiAllenLumiSummaryToRawEvent final
  : public LHCb::Algorithm::MultiTransformer<
      std::tuple<LHCb::RawEvent, LHCb::RawBank::View>(const std::vector<unsigned>&, const std::vector<unsigned>&)> {
  // Standard constructor
  GaudiAllenLumiSummaryToRawEvent(const std::string& name, ISvcLocator* pSvcLocator);

  // Algorithm execution
  std::tuple<LHCb::RawEvent, LHCb::RawBank::View> operator()(
    const std::vector<unsigned>& allen_lumi_summaries,
    const std::vector<unsigned>& allen_lumi_summary_offsets) const override;
};

DECLARE_COMPONENT(GaudiAllenLumiSummaryToRawEvent)

GaudiAllenLumiSummaryToRawEvent::GaudiAllenLumiSummaryToRawEvent(const std::string& name, ISvcLocator* pSvcLocator) :
  MultiTransformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_lumi_summaries", ""}, KeyValue {"allen_lumi_summary_offsets", ""}},
    // Outputs
    {KeyValue {"OutputLumiSummary", "Allen/Out/LumiSummary"},
     KeyValue {"OutputLumiSummaryView", "Allen/Out/LumiSummaryView"}})
{}

std::tuple<LHCb::RawEvent, LHCb::RawBank::View> GaudiAllenLumiSummaryToRawEvent::operator()(
  const std::vector<unsigned>& allen_lumi_summaries,
  const std::vector<unsigned>& allen_lumi_summary_offsets) const
{

  LHCb::RawEvent raw_event;
  auto lumi_summaries = LHCb::span {allen_lumi_summaries}.first(allen_lumi_summary_offsets[1]);
  if (!lumi_summaries.empty()) {
    raw_event.addBank(Hlt1::Constants::sourceID, LHCb::RawBank::HltLumiSummary, 2u, lumi_summaries);
  }
  auto lumi_view = raw_event.banks(LHCb::RawBank::HltLumiSummary);

  return {std::move(raw_event), std::move(lumi_view)};
}
