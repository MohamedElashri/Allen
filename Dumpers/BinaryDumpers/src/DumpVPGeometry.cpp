/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#include <tuple>
#include <vector>
//#include "DumpVPGeometry.h"
#include "GaudiKernel/SystemOfUnits.h"
#include "Detector/VP/VPChannelID.h"
#include <boost/numeric/conversion/cast.hpp>
#include <VPDet/DeVP.h>
#include <Dumpers/Utils.h>

// LHCb
#include <DetDesc/Condition.h>
#include <DetDesc/ConditionAccessorHolder.h>
#include "DetDesc/IConditionDerivationMgr.h"


// Gaudi
#include "GaudiAlg/Transformer.h"

#include <Dumpers/Identifiers.h>


/** @class DumpVPGeometry
 *  Dump Calo Geometry.
 *
 *  @author Nabil Garroum
 *  @date   2022-04-15
 */

class DumpVPGeometry final
  : public Gaudi::Functional::MultiTransformer<std::tuple<std::vector<char>, std::string>(
                                                const DeVP&),
                                            LHCb::DetDesc::usesConditions<DeVP>> {
public:

  DumpVPGeometry( const std::string& name, ISvcLocator* svcLoc );

  std::tuple<std::vector<char>, std::string> operator()( const DeVP& DeVP ) const override;

  Gaudi::Property<std::string> m_id{this, "ID", Allen::NonEventData::VeloGeometry::id};
  
  //Gaudi::Property<bool> m_dumpToFile {this, "DumpToFile", true};
  //Gaudi::Property<std::string> m_outputDirectory {this, "OutputDirectory", "velo_geometry"};
};



DECLARE_COMPONENT(DumpVPGeometry)



// StatusCode DumpVPGeometry::registerConditions(IUpdateManagerSvc* updMgrSvc)
// {
// #ifndef USE_DD4HEP
//   auto& det = detector();
//   return updMgrSvc->update(&det);
// #else
//   return StatusCode::SUCCESS;
// #endif
// }


// Add the multitransformer call , which keyvalues ?

DumpVPGeometry::DumpVPGeometry( const std::string& name, ISvcLocator* svcLoc )
    : MultiTransformer( name, svcLoc,
                   {KeyValue{"VPLocation", DeVPLocation::Default}},
                   {KeyValue{"Converted", "Allen/NonEventData/DeVP"},
                    KeyValue{"OutputID", "Allen/NonEventData/DeVPID"}}) {}



// Add the operator() call

std::tuple<std::vector<char>, std::string> DumpVPGeometry::operator()( const DeVP& det ) const 
{

// DumpUtils::Dumps DumpVPGeometry::dumpGeometry() const
// {

  // auto const& det = detector();

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

  // return {{std::tuple {output.buffer(), "velo_geometry", Allen::NonEventData::VeloGeometry::id}}};
  return std::tuple {output.buffer(), m_id};

}

