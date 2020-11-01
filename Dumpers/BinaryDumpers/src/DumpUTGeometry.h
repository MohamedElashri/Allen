/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef DUMPUTGEOMETRY_H
#define DUMPUTGEOMETRY_H 1

// Include files
#include "DumpGeometry.h"
#include <UTDet/DeUTDetector.h>

/** @class DumpUTGeometry
 *  Class that dumps the UT geometry
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class DumpUTGeometry final : public DumpGeometry<DeUTDetector> {
public:
  DumpUTGeometry(std::string name, ISvcLocator* loc) :
    DumpGeometry<DeUTDetector> {std::move(name), loc, DeUTDetLocation::UT}
  {}

protected:
  DumpUtils::Dumps dumpGeometry() const override;

private:
  DumpUtils::Dump dumpGeom() const;
  DumpUtils::Dump dumpBoards() const;
};

#endif // DUMPUTGEOMETRY_H
