/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

// Include files
#include "DumpGeometry.h"
#include <MuonDet/DeMuonDetector.h>

/** @class DumpMuonTable
 *  Dump muon position lookup table
 *
 *  @author Roel Aaij
 *  @date   2019-02-21
 */
class DumpMuonTable final : public DumpGeometry<DeMuonDetector> {
public:
  DumpMuonTable(std::string name, ISvcLocator* loc) :
    DumpGeometry<DeMuonDetector> {std::move(name), loc, "/dd/Structure/LHCb/DownstreamRegion/Muon"}
  {}

protected:
  DumpUtils::Dumps dumpGeometry() const override;
};
