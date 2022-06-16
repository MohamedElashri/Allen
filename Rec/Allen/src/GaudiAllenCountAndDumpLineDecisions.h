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
#pragma once

// Gaudi
#include "GaudiAlg/Consumer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/RawEvent.h"

// Standard
#include <vector>
#include <deque>

struct GaudiAllenCountAndDumpLineDecisions final : public Gaudi::Functional::Consumer<void(
                                                     const std::vector<unsigned>&,
                                                     const std::vector<char>&,
                                                     const std::vector<char>&,
                                                     const std::vector<unsigned>&)> {
  // Standard constructor
  GaudiAllenCountAndDumpLineDecisions(const std::string& name, ISvcLocator* pSvcLocator);

  /// Initialization
  StatusCode initialize() override;

  void operator()(
    const std::vector<unsigned>& allen_number_of_active_lines,
    const std::vector<char>& allen_names_of_active_lines,
    const std::vector<char>& allen_selections,
    const std::vector<unsigned>& allen_selections_offsets) const override;

private:
  bool check_line_names(const std::vector<char>&) const;

  Gaudi::Property<bool> m_check_names {this,
                                       "CheckLineNamesAndOrder",
                                       true,
                                       "Flag to perform line name check for each event."};
  Gaudi::Property<std::vector<std::string>> m_line_names {this,
                                                          "Hlt1LineNames",
                                                          {},
                                                          "Ordered list of Allen line names"};

  // Counters for HLT1 selection rates
  mutable std::deque<Gaudi::Accumulators::BinomialCounter<uint32_t>> m_hlt1_line_rates {};
};
