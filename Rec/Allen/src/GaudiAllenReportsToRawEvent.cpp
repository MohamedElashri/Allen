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
// Gaudi
#include "LHCbAlgs/Transformer.h"
#include "Event/RawEvent.h"
#include <vector>
#include "Kernel/STLExtensions.h"
#include "HltDecReport.cuh"
#include "HltConstants.cuh"
#include <RoutingBitsDefinition.h>

class GaudiAllenReportsToRawEvent
  : public LHCb::Algorithm::MultiTransformer<
      std::tuple<LHCb::RawEvent, LHCb::RawBank::View, LHCb::RawBank::View, LHCb::RawBank::View>(
        const std::vector<unsigned>&,
        const std::vector<unsigned>&,
        const std::vector<unsigned>&,
        const std::vector<unsigned>&),
      LHCb::Algorithm::Traits::writeOnly<LHCb::RawEvent>> {
public:
  // Standard constructor
  GaudiAllenReportsToRawEvent(const std::string& name, ISvcLocator* pSvcLocator) :
    MultiTransformer {name,
                      pSvcLocator,
                      // Inputs
                      {KeyValue {"allen_dec_reports", ""},
                       KeyValue {"allen_selrep_offsets", ""},
                       KeyValue {"allen_sel_reports", ""},
                       KeyValue {"allen_routing_bits", ""}},
                      // Outputs
                      {KeyValue {"OutputRawReports", "Allen/Out/RawReports"},
                       KeyValue {"OutputDecView", "Allen/Out/OutputDecView"},
                       KeyValue {"OutputSelView", "Allen/Out/OutputSelView"},
                       KeyValue {"OutputRoutingBitsView", "Allen/Out/OutputRoutingBitsView"}}}
  {}

  // Algorithm execution
  std::tuple<LHCb::RawEvent, LHCb::RawBank::View, LHCb::RawBank::View, LHCb::RawBank::View> operator()(
    const std::vector<unsigned>& allen_dec_reports,
    const std::vector<unsigned>& allen_selrep_offsets,
    const std::vector<unsigned>& allen_sel_reports,
    const std::vector<unsigned>& allen_routing_bits) const override
  {
    LHCb::RawEvent raw_event;
    auto dec_reports = HltDecReports {allen_dec_reports, 0};
    auto sel_reports = LHCb::span {allen_sel_reports}.first(allen_selrep_offsets[1]);
    auto routing_bits = LHCb::span {allen_routing_bits}.first(RoutingBitsDefinition::n_words);
    raw_event.addBank(
      Hlt1::Constants::sourceID_sel_reports,
      LHCb::RawBank::HltSelReports,
      Hlt1::Constants::version_sel_reports,
      sel_reports);
    raw_event.addBank(
      Hlt1::Constants::sourceID, LHCb::RawBank::HltDecReports, dec_reports.version(), dec_reports.bank_data());
    raw_event.addBank(Hlt1::Constants::sourceID, LHCb::RawBank::HltRoutingBits, 0u, routing_bits);

    auto dec_view = raw_event.banks(LHCb::RawBank::HltDecReports);
    auto sel_view = raw_event.banks(LHCb::RawBank::HltSelReports);
    auto rb_view = raw_event.banks(LHCb::RawBank::HltRoutingBits);
    // without std::move here the RawEvent gets copied which would invalidate the view
    // View creation must be after RawEvent is made
    return {std::move(raw_event), std::move(dec_view), std::move(sel_view), std::move(rb_view)};
  }
};

DECLARE_COMPONENT(GaudiAllenReportsToRawEvent)
