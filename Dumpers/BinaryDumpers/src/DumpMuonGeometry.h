/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

// Include files
#include "DumpGeometry.h"
#include <MuonDet/DeMuonDetector.h>

/** @class DumpMuonGeometry
 *  Dump muon geometry information
 *
 *  @author Roel Aaij
 *  @date   2019-02-21
 */
class DumpMuonGeometry final : public DumpGeometry<DeMuonDetector> {
public:
  DumpMuonGeometry(std::string name, ISvcLocator* loc) :
    DumpGeometry<DeMuonDetector> {std::move(name), loc, DeMuonLocation::Default}
  {}

protected:
  StatusCode registerConditions(IUpdateManagerSvc* updMgrSvc) override;
  DumpUtils::Dumps dumpGeometry() const override;

private:
  mutable MuonDAQHelper m_daqHelper;
};
