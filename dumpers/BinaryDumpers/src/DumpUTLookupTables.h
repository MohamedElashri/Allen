/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
