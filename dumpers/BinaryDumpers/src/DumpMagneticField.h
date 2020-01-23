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
#ifndef DUMPMAGNETICFIELD_H
#define DUMPMAGNETICFIELD_H 1

// Include files
#include "DumpGeometry.h"
#include <Kernel/ILHCbMagnetSvc.h>

/** @class DumpMagneticField
 *  Dump magnetic field. Implements DumpGeometry.
 *
 *  @author Roel Aaij
 *  @date   2019-04-27
 */
class DumpMagneticField final : public DumpGeometry<ILHCbMagnetSvc> {
public:
  DumpMagneticField( std::string name, ISvcLocator* loc )
      : DumpGeometry<ILHCbMagnetSvc>{std::move( name ), loc, "MagneticFieldSvc"} {}

protected:
  DumpUtils::Dumps dumpGeometry() const override;
};

#endif // DUMPMAGNETICFIELD_H
