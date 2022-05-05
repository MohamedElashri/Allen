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
#include <DetDesc/Condition.h>
#include <DetDesc/ConditionAccessorHolder.h>
#include "DetDesc/IConditionDerivationMgr.h"
#include "Detector/VP/VPChannelID.h"
#include <boost/numeric/conversion/cast.hpp>
#include <VPDet/DeVP.h>

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/SystemOfUnits.h"

// Allen
#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
//#include "DumpVPGeometry.h"  , Old header, delted for this class

/** @class DumpVPGeometry
 *  Dump Calo Geometry.
 *
 *  @author Nabil Garroum
 *  @date   2022-04-15
 *  This Class dumps geometry for Velo using DD4HEP and Gaudi Algorithm
 *  This Class uses a detector description
 *  This Class is basically an instation of a Gaudi algorithm with specific inputs and outputs:
 *  The role of this class is to get data from TES to Allen for the Velo Geometry
 */

class DumpVPGeometry final
  : public Gaudi::Functional::
      MultiTransformer<std::tuple<std::vector<char>, std::string>(const DeVP&), LHCb::DetDesc::usesConditions<DeVP>> {
public:
  DumpVPGeometry(const std::string& name, ISvcLocator* svcLoc);

  std::tuple<std::vector<char>, std::string> operator()(const DeVP& DeVP) const override;

  Gaudi::Property<std::string> m_id {this, "ID", Allen::NonEventData::VeloGeometry::id};
};

DECLARE_COMPONENT(DumpVPGeometry)

// Add the multitransformer call

DumpVPGeometry::DumpVPGeometry(const std::string& name, ISvcLocator* svcLoc) :
  MultiTransformer(
    name,
    svcLoc,
    {KeyValue {"VPLocation", DeVPLocation::Default}},
    {KeyValue {"Converted", "Allen/NonEventData/DeVP"}, KeyValue {"OutputID", "Allen/NonEventData/DeVPID"}})
{}

// MultiTrasnformer algorithm with 1 input and 2 outputs , cf Gaudi algorithmas taxonomy as reference.

// Add the operator() call

std::tuple<std::vector<char>, std::string> DumpVPGeometry::operator()(const DeVP& det) const
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

  // Final data output

  return std::tuple {output.buffer(), m_id};
}
