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
#include <tuple>
#include <vector>

#include "DumpMagneticField.h"

DECLARE_COMPONENT(DumpMagneticField)

DumpUtils::Dumps DumpMagneticField::dumpGeometry() const
{

  auto& magnetSvc = detector();

  DumpUtils::Writer output {};
  float polarity = magnetSvc.isDown() ? -1.f : 1.f;
  output.write(polarity);

  return {{std::tuple {output.buffer(), "polarity", Allen::NonEventData::MagneticField::id}}};
}
