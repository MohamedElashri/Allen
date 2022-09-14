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
#include "GaudiAlg/Transformer.h"
#include "Event/RawEvent.h"
#include <vector>
#include "Kernel/STLExtensions.h"

struct GaudiAllenReportsToRawEvent final : public Gaudi::Functional::Transformer<LHCb::RawEvent(
                                             const std::vector<unsigned>&,
                                             const std::vector<unsigned>&,
                                             const std::vector<unsigned>&,
                                             const std::vector<unsigned>&)> {
  // Standard constructor
  GaudiAllenReportsToRawEvent(const std::string& name, ISvcLocator* pSvcLocator) :
    Transformer(
      name,
      pSvcLocator,
      // Inputs
      {KeyValue {"allen_number_of_active_lines", ""},
       KeyValue {"allen_dec_reports", ""},
       KeyValue {"allen_selrep_offsets", ""},
       KeyValue {"allen_sel_reports", ""}},
      // Outputs
      {KeyValue {"OutputRawReports", "Allen/Out/RawReports"}})
  {}

  // Algorithm execution
  LHCb::RawEvent operator()(
    const std::vector<unsigned>& allen_number_of_active_lines,
    const std::vector<unsigned>& allen_dec_reports,
    const std::vector<unsigned>& allen_selrep_offsets,
    const std::vector<unsigned>& allen_sel_reports) const override
  {
    LHCb::RawEvent raw_event;
    // TODO: get these hard coded numbers from somewhere else... should be defined in one location only!
    constexpr auto hlt1SourceID_old = (1u << 13);
    constexpr auto hlt1SourceID_new = (1u << 8);
    constexpr auto sel_rep_version = 9u, dec_rep_version = 3u;
    auto dec_reports = LHCb::span {allen_dec_reports}.first(3 + allen_number_of_active_lines[0]);
    auto sel_reports = LHCb::span {allen_sel_reports}.first(allen_selrep_offsets[1]);
    raw_event.addBank(hlt1SourceID_old, LHCb::RawBank::HltSelReports, sel_rep_version, sel_reports);
    raw_event.addBank(hlt1SourceID_new, LHCb::RawBank::HltDecReports, dec_rep_version, dec_reports);

    return raw_event;
  }
};

DECLARE_COMPONENT(GaudiAllenReportsToRawEvent)
