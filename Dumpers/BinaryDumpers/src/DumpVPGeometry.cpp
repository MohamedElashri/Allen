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
#include "GaudiKernel/SystemOfUnits.h"

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

namespace {
  inline const std::string VPGeoCond = DeVPLocation::Default;

  struct VPGeometry {

    VPGeometry() = default;
    VPGeometry(std::vector<char>& data, const DeVP& det)
    {
      DumpUtils::Writer output {};
      const size_t sensorPerModule = 4;
      std::vector<float> zs(det.numberSensors() / sensorPerModule, 0.f);
      det.runOnAllSensors([&zs](const DeVPSensor& sensor) {
        zs[sensor.module()] += boost::numeric_cast<float>(sensor.z() / sensorPerModule);
      });

      output.write(zs.size(), zs, size_t {VP::NSensorColumns});
      for (unsigned int i = 0; i < VP::NSensorColumns; i++)
        output.write(det.local_x(i));
      output.write(size_t {VP::NSensorColumns});
      for (unsigned int i = 0; i < VP::NSensorColumns; i++)
        output.write(det.x_pitch(i));
      output.write(size_t {VP::NSensors}, size_t {12});
      for (unsigned int i = 0; i < VP::NSensors; i++)
        output.write(det.ltg(LHCb::Detector::VPChannelID::SensorID {i}));

      data = output.buffer();
    }
  };
} // namespace

class DumpVPGeometry final
  : public Allen::Dumpers::Dumper<void(VPGeometry const&), LHCb::DetDesc::usesConditions<VPGeometry>> {
public:
  DumpVPGeometry(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const VPGeometry& VPGeo) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpVPGeometry)

// Add the multitransformer call

DumpVPGeometry::DumpVPGeometry(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"VPGeometryLocation", location(name, "geometry")}})
{}

StatusCode DumpVPGeometry::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::VeloGeometry::id, "VP_geometry", m_data);
    addConditionDerivation({VPGeoCond}, inputLocation<VPGeometry>(), [&](DeVP const& det) {
      auto VPGeo = VPGeometry {m_data, det};
      dump();
      return VPGeo;
    });
  });
}

void DumpVPGeometry::operator()(const VPGeometry&) const {}