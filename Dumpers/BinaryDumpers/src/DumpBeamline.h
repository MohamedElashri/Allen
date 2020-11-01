/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef DUMPBEAMLINE_H
#define DUMPBEAMLINE_H 1

// Include files
#include "DumpGeometry.h"
#include <DetDesc/Condition.h>

/** @class DumpBeamline
 *  Dump magnetic field. Implements DumpGeometry.
 *
 *  @author Roel Aaij
 *  @date   2019-04-27
 */
class DumpBeamline final : public DumpGeometry<Condition> {
public:
  DumpBeamline(std::string name, ISvcLocator* loc) :
    DumpGeometry<Condition> {std::move(name), loc, "/dd/Conditions/Online/Velo/MotionSystem"}
  {}

protected:
  DumpUtils::Dumps dumpGeometry() const override;
};

#endif // DUMPBEAMLINE_H
