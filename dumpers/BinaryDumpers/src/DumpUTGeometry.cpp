/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

#include "range/v3/version.hpp"
#include <range/v3/view/repeat_n.hpp>
#include <range/v3/view/transform.hpp>
#if RANGE_V3_VERSION < 900
namespace ranges::views {
  using namespace ranges::view;
}
#  include "range/v3/to_container.hpp"
namespace ranges {
  template <typename C>
  inline constexpr auto to = to_<C>;
}
#else
#  include "range/v3/range/conversion.hpp"
#endif

#include <Kernel/IUTReadoutTool.h>
#include <Kernel/UTTell1Board.h>

#include "DumpUTGeometry.h"

namespace {
  using std::vector;

  using namespace ranges;
} // namespace

DECLARE_COMPONENT( DumpUTGeometry )

DumpUtils::Dump DumpUTGeometry::dumpGeom() const {
  const auto& sectors           = detector().sectors();
  uint32_t    number_of_sectors = sectors.size();
  // first strip is always 1
  vector<uint32_t> firstStrip = views::repeat_n( 1, number_of_sectors ) | to<std::vector<uint32_t>>();
  vector<float>    pitch      = views::transform( sectors, &DeUTSector::pitch ) | to<std::vector<float>>();
  vector<float>    cos        = views::transform( sectors, &DeUTSector::cosAngle ) | to<std::vector<float>>();
  vector<float>    dy;
  vector<float>    dp0diX;
  vector<float>    dp0diY;
  vector<float>    dp0diZ;
  vector<float>    p0X;
  vector<float>    p0Y;
  vector<float>    p0Z;

  dy.reserve( number_of_sectors );
  dp0diX.reserve( number_of_sectors );
  dp0diY.reserve( number_of_sectors );
  dp0diZ.reserve( number_of_sectors );
  p0X.reserve( number_of_sectors );
  p0Y.reserve( number_of_sectors );
  p0Z.reserve( number_of_sectors );

  // This code comes from DeUTSector::cacheInfo
  for ( const auto sector : sectors ) {
    auto firstTraj = sector->trajectoryFirstStrip();

    // get the start and end point. for piecewise trajectories, we
    // effectively make an approximation by a straight line.
    const Gaudi::XYZPoint g1 = firstTraj.beginPoint();
    const Gaudi::XYZPoint g2 = firstTraj.endPoint();

    const double activeWidth = sector->sensors().front()->activeWidth();

    // direction
    Gaudi::XYZVector direction = g2 - g1;
    direction                  = direction.Unit();

    // cross with normal along z
    Gaudi::XYZVector zVec( 0, 0, 1 );
    Gaudi::XYZVector norm = direction.Cross( zVec );

    // trajectory of middle
    const Gaudi::XYZPoint g3 = g1 + 0.5 * ( g2 - g1 );
    const Gaudi::XYZPoint g4 = g3 + activeWidth * norm;

    // creating the 'fast' trajectories
    const Gaudi::XYZVector vectorlayer = ( g4 - g3 ).unit() * sector->pitch();
    const Gaudi::XYZPoint  p0          = g3 - 0.5 * sector->stripLength() * direction;
    auto                   dxdy        = direction.x() / direction.y();
    auto                   dzdy        = direction.z() / direction.y();
    auto                   sdy         = sector->stripLength() * direction.y();

    dy.push_back( sdy );
    dp0diX.push_back( vectorlayer.x() - vectorlayer.y() * dxdy );
    dp0diY.push_back( vectorlayer.y() );
    dp0diZ.push_back( vectorlayer.z() - vectorlayer.y() * dzdy );
    p0X.push_back( p0.x() - p0.y() * dxdy );
    p0Y.push_back( p0.y() );
    p0Z.push_back( p0.z() - p0.y() * dzdy );
  }

  DumpUtils::Writer ut_geometry{};
  ut_geometry.write( number_of_sectors, firstStrip, pitch, dy, dp0diX, dp0diY, dp0diZ, p0X, p0Y, p0Z, cos );

  return std::tuple{ut_geometry.buffer(), "ut_geometry", Allen::NonEventData::UTGeometry::id};
}

DumpUtils::Dump DumpUTGeometry::dumpBoards() const {
  std::vector<uint32_t> stripsPerHybrids;
  std::vector<uint32_t> stations;
  std::vector<uint32_t> layers;
  std::vector<uint32_t> detRegions;
  std::vector<uint32_t> sectors;
  std::vector<uint32_t> chanIDs;

  auto readout = tool<IUTReadoutTool>( "UTReadoutTool" );
  if ( !readout ) { throw GaudiException{"Failed to obtain readout tool.", name(), StatusCode::FAILURE}; }

  // Strips per hybrid cannot be obtained from the boards, so use the
  // condition where it came from instead.
  // This can be found in UTReadoutTool
  std::string  conditionLocation = "/dd/Conditions/ReadoutConf/UT/ReadoutMap";
  Condition*   rInfo             = getDet<Condition>( conditionLocation );
  auto         hybridsPerBoard   = rInfo->param<int>( "hybridsPerBoard" );
  unsigned int stripsPerHybrid   = UTDAQ::nStripsPerBoard / hybridsPerBoard;

  uint32_t currentBoardID = 0, cbID = 0;
  for ( ; cbID < readout->nBoard(); ++cbID ) {
    auto           b       = readout->findByOrder( cbID );
    const uint32_t boardID = b->boardID().id();

    // Insert empty boards if there is a gap between the last boardID and the
    // current one
    for ( ; boardID != 0 && currentBoardID < boardID; ++currentBoardID ) {
      stripsPerHybrids.push_back( 0 );
      for ( uint32_t i = 0; i < 6; ++i ) {
        stations.push_back( 0 );
        layers.push_back( 0 );
        detRegions.push_back( 0 );
        sectors.push_back( 0 );
        chanIDs.push_back( 0 );
      }
    }

    stripsPerHybrids.push_back( stripsPerHybrid );

    for ( size_t is = 0; is < b->nSectors(); ++is ) {
      auto r = b->DAQToOfflineFull( 0, UTDAQ::v4, is * stripsPerHybrid );
      auto s = std::get<0>( r );
      stations.push_back( s.station );
      layers.push_back( s.layer );
      detRegions.push_back( s.detRegion );
      sectors.push_back( s.sector );
      chanIDs.push_back( s.chanID );
    }
    // If the number of sectors is less than 6, fill the remaining ones up to 6 with zeros
    // this is necessary to be compatible with the Allen UT boards layout
    for ( size_t is = b->nSectors(); is < 6; ++is ) {
      stations.push_back( 0 );
      layers.push_back( 0 );
      detRegions.push_back( 0 );
      sectors.push_back( 0 );
      chanIDs.push_back( 0 );
    }
    ++currentBoardID;
  }

  DumpUtils::Writer ut_boards{};
  ut_boards.write( currentBoardID, stripsPerHybrids, stations, layers, detRegions, sectors, chanIDs );

  return std::tuple{ut_boards.buffer(), "ut_boards", Allen::NonEventData::UTBoards::id};
}

DumpUtils::Dumps DumpUTGeometry::dumpGeometry() const { return {{dumpGeom(), dumpBoards()}}; }
