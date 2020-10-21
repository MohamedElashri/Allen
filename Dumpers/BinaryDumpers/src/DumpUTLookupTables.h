/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef DUMPUTLOOKUPTABLES_H
#define DUMPUTLOOKUPTABLES_H 1

// Include files
#include "DumpGeometry.h"
#include <PrKernel/IPrUTMagnetTool.h>

/** @class DumpUTLookupTables
 *  Dump magnetic field. Implements DumpGeometry.
 *
 *  @author Roel Aaij
 *  @date   2019-04-27
 */
class DumpUTLookupTables final : public DumpGeometry<IPrUTMagnetTool> {
public:
  DumpUTLookupTables(std::string name, ISvcLocator* loc) :
    DumpGeometry<IPrUTMagnetTool> {std::move(name), loc, "PrUTMagnetTool"}
  {}

protected:
  DumpUtils::Dumps dumpGeometry() const override;
};

#endif // DUMPUTLOOKUPTABLES_H
