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
