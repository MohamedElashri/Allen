/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
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
