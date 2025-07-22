/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include <tuple>
#include <vector>

// LHCb
// #include <DetDesc/Condition.h>
// #include <DetDesc/ConditionAccessorHolder.h>
// #include "DetDesc/IConditionDerivationMgr.h"
#include "Detector/VP/VPChannelID.h"
#include <boost/numeric/conversion/cast.hpp>
#include <VPDet/DeVP.h>

#include <DetDesc/GenericConditionAccessorHolder.h>

// Gaudi
#include "GaudiAlg/Transformer.h"

// Allen
#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
#include "Dumper.h"

/** @class DumpVPGeometry
 *  Dump Velo Geometry.
 *
 *  @author Nabil Garroum
 *  @date   2022-04-15
 *  This Class dumps geometry for Velo using DD4HEP and Gaudi Algorithm
 *  This Class uses a detector description
 *  This Class is basically an instation of a Gaudi algorithm with specific inputs and outputs:
 *  The role of this class is to get data from TES to Allen for the Velo Geometry
 */

namespace Dumpers {
  struct VP {

    VP() = default;
    VP(std::vector<char>& data, const DeVP& det)
    {
      DumpUtils::Writer output {};
      const size_t sensorPerModule = 4;
      std::vector<float> zs(det.numberSensors() / sensorPerModule, 0.f);
      det.runOnAllSensors([&zs](const DeVPSensor& sensor) {
        zs[sensor.module()] += boost::numeric_cast<float>(sensor.z() / sensorPerModule);
      });

      output.write(zs.size(), zs, size_t {::VP::NSensorColumns});
      for (unsigned int i = 0; i < ::VP::NSensorColumns; i++)
        output.write(det.local_x(i));
      output.write(size_t {::VP::NSensorColumns});
      for (unsigned int i = 0; i < ::VP::NSensorColumns; i++)
        output.write(det.x_pitch(i));
      output.write(size_t {::VP::NSensors}, size_t {12});
      for (unsigned int i = 0; i < ::VP::NSensors; i++)
        output.write(det.ltg(LHCb::Detector::VPChannelID::SensorID {i}));

      data = output.buffer();
    }
  };
} // namespace Dumpers

class DumpVPGeometry final
  : public Allen::Dumpers::Dumper<void(Dumpers::VP const&), LHCb::Algorithm::Traits::usesConditions<Dumpers::VP>> {
public:
  DumpVPGeometry(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const Dumpers::VP& VP) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpVPGeometry)

// Add the multitransformer call

DumpVPGeometry::DumpVPGeometry(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"VPLocation", location(name, "geometry")}})
{}

StatusCode DumpVPGeometry::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::VeloGeometry::id, "velo_geometry", m_data);
    addConditionDerivation({DeVPLocation::Default}, inputLocation<Dumpers::VP>(), [&](DeVP const& det) {
      auto geo = Dumpers::VP {m_data, det};
      dump();
      return geo;
    });
  });
}

void DumpVPGeometry::operator()(const Dumpers::VP&) const {}
