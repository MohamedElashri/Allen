/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/FilterPredicate.h"
#include "Gaudi/Accumulators.h"

// Standard
#include <vector>
#include <algorithm>

struct GaudiAllenFilterEventsLineDecisions final
  : public Gaudi::Functional::FilterPredicate<bool(const std::vector<char>&)> {
  GaudiAllenFilterEventsLineDecisions(const std::string& name, ISvcLocator* pSvcLocator) :
    FilterPredicate(name, pSvcLocator, {KeyValue {"allen_global_decision", ""}})
  {}

  bool operator()(const std::vector<char>& allen_global_decision) const override
  {
    assert(allen_global_decision.size() == 1);

    // Check if event passed selection
    bool passed = allen_global_decision[0];
    m_passed += passed;
    return passed;
  }

private:
  mutable Gaudi::Accumulators::BinomialCounter<uint32_t> m_passed {};
};

DECLARE_COMPONENT(GaudiAllenFilterEventsLineDecisions)
