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
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/RawEvent.h"

// Standard
#include <vector>

struct GaudiAllenReportsToRawEvent final : public Gaudi::Functional::Transformer<LHCb::RawEvent(
                                             const std::vector<unsigned>&,
                                             const std::vector<unsigned>&,
                                             const std::vector<unsigned>&,
                                             const std::vector<unsigned>&)> {
  // Standard constructor
  GaudiAllenReportsToRawEvent(const std::string& name, ISvcLocator* pSvcLocator);

  // Algorithm execution
  LHCb::RawEvent operator()(
    const std::vector<unsigned>& allen_number_of_active_lines,
    const std::vector<unsigned>& allen_dec_reports,
    const std::vector<unsigned>& allen_selrep_offsets,
    const std::vector<unsigned>& allen_sel_reports) const override;
};
