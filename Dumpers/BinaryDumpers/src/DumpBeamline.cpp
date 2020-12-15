/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <tuple>
#include <vector>

#include "DumpBeamline.h"

DECLARE_COMPONENT(DumpBeamline)

DumpUtils::Dumps DumpBeamline::dumpGeometry() const
{

  auto& cond = detector();

  DumpUtils::Writer output {};

  const float xRC = cond.paramAsDouble("ResolPosRC");
  const float xLA = cond.paramAsDouble("ResolPosLA");
  const float y = cond.paramAsDouble("ResolPosY");

  float x = (xRC + xLA) / 2.f;
  output.write(x, y);

  return {{std::tuple {output.buffer(), "beamline", Allen::NonEventData::Beamline::id}}};
}
