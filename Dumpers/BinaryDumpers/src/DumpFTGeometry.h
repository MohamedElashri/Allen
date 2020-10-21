/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef DUMPFTGEOMETRY_H
#define DUMPFTGEOMETRY_H 1

// Include files
#include "DumpGeometry.h"
#include <FTDet/DeFTDetector.h>

/** @class DumpFTGeometry
 *  Dump geometry of the SciFi tracker. Implements DumpGeometry.
 *
 *  @author Lars Funke
 *  @date   2018-09-03
 */
class DumpFTGeometry final : public DumpGeometry<DeFTDetector> {
public:
  DumpFTGeometry(std::string name, ISvcLocator* loc) :
    DumpGeometry<DeFTDetector> {std::move(name), loc, DeFTDetectorLocation::Default}
  {}

protected:
  DumpUtils::Dumps dumpGeometry() const override;
};

#endif // DUMPUTGEOMETRY_H
