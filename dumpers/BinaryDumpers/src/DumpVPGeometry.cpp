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

#include "DumpVPGeometry.h"
#include <GaudiKernel/SystemOfUnits.h>

#include <boost/numeric/conversion/cast.hpp>

DECLARE_COMPONENT( DumpVPGeometry )

StatusCode DumpVPGeometry::registerConditions( IUpdateManagerSvc* updMgrSvc ) {
  auto& det = detector();
  return updMgrSvc->update( &det );
}

DumpUtils::Dumps DumpVPGeometry::dumpGeometry() const {

  auto const& det = detector();

  DumpUtils::Writer  output{};
  const size_t       sensorPerModule = 4;
  std::vector<float> zs( det.numberSensors() / sensorPerModule, 0.f );
  det.runOnAllSensors( [&zs]( const DeVPSensor& sensor ) {
    zs[sensor.module()] += boost::numeric_cast<float>( sensor.z() / sensorPerModule );
  } );

  output.write( zs.size(), zs, size_t{VP::NSensorColumns} );
  for ( unsigned int i = 0; i < VP::NSensorColumns; i++ ) output.write( det.local_x( i ) );
  output.write( size_t{VP::NSensorColumns} );
  for ( unsigned int i = 0; i < VP::NSensorColumns; i++ ) output.write( det.x_pitch( i ) );
  output.write( size_t{VP::NSensors}, size_t{12} );
  for ( unsigned int i = 0; i < VP::NSensors; i++ ) output.write( det.ltg( i ) );

  return {{std::tuple{output.buffer(), "velo_geometry", Allen::NonEventData::VeloGeometry::id}}};
}
