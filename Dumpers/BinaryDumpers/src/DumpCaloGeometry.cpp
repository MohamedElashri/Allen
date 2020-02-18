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
#include <array>
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

#include "DumpCaloGeometry.h"
#include "Utils.h"

DECLARE_COMPONENT(DumpCaloGeometry)

namespace {
  const std::map<std::string, std::string> ids = {{"EcalDet", Allen::NonEventData::ECalGeometry::id},
                                                  {"HcalDet", Allen::NonEventData::HCalGeometry::id}};
  using namespace std::string_literals;
}

DumpUtils::Dumps DumpCaloGeometry::dumpGeometry() const
{

  // Detector and mat geometry
  const auto& det = detector();

  std::array<unsigned int, 4> test;
  DumpUtils::Writer output {};
  output.write(
    test.size(),
    test);

  auto id = ids.find(det.caloName());
  if (id == ids.end()) {
    throw GaudiException{"Cannot find "s + det.caloName(), name(), StatusCode::FAILURE};
  }
  return {{std::tuple {output.buffer(), det.caloName() + "_geometry", id->second}}};
}
