/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef DUMPVPGEOMETRY_H
#define DUMPVPGEOMETRY_H 1

// Include files
#include "DumpGeometry.h"
#include <VPDet/DeVP.h>

/** @class DumpVPGeometry
 *  Dump geometry of the VeloPix tracker. Implements DumpGeometry.
 *
 *  @author Roel Aaij
 *  @date   2019-04-23
 */
class DumpVPGeometry final : public DumpGeometry<DeVP> {
public:
  DumpVPGeometry(std::string name, ISvcLocator* loc) : DumpGeometry<DeVP> {std::move(name), loc, DeVPLocation::Default}
  {}

protected:
  StatusCode registerConditions(IUpdateManagerSvc* updMgrSvc) override;

  DumpUtils::Dumps dumpGeometry() const override;
};

#endif // DUMPUTGEOMETRY_H
