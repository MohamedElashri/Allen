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
#include <sstream>
#include <vector>

#include <range/v3/algorithm/any_of.hpp>
#include <range/v3/algorithm/fill.hpp>
#include <range/v3/core.hpp>
#include <range/v3/numeric/accumulate.hpp>
#include <range/v3/view/cartesian_product.hpp>
#include <range/v3/view/concat.hpp>
#include <range/v3/view/iota.hpp>
#include <range/v3/view/take.hpp>

#if RANGE_V3_VERSION < 900
namespace ranges::views {
  using namespace ranges::view;
}
#endif

#include <boost/format.hpp>
#include <boost/numeric/conversion/cast.hpp>

#include "DumpMuonTable.h"
#include "Utils.h"

namespace {
  using boost::numeric_cast;
  using std::array;
  using std::ios;
  using std::ofstream;
  using std::string;
  using std::tuple;
  using std::vector;
  using namespace ranges;

  constexpr array<int, 16> padGridX{48, 48, 48, 48, 48, 48, 48, 48, 12, 12, 12, 12, 12, 12, 12, 12};
  constexpr array<int, 16> padGridY{8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};
  constexpr array<int, 16> stripXGridX{48, 48, 48, 48, 48, 48, 48, 48, 12, 12, 12, 12, 12, 12, 12, 12};
  constexpr array<int, 16> stripXGridY{1, 2, 2, 2, 1, 2, 2, 2, 8, 2, 2, 2, 8, 2, 2, 2};
  constexpr array<int, 16> stripYGridX{8, 4, 2, 2, 8, 4, 2, 2, 12, 4, 2, 2, 12, 4, 2, 2};
  constexpr array<int, 16> stripYGridY{8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};

} // namespace

DECLARE_COMPONENT( DumpMuonTable )

DumpUtils::Dumps DumpMuonTable::dumpGeometry() const {

  // Detector and mat geometry
  const auto& det       = detector();
  const int   nStations = det.stations();
  assert( nStations == 4 );
  const int nRegions = det.regions() / nStations;
  assert( nRegions == 4 );

  vector<float>           padSizeX{}, stripXSizeX{}, stripYSizeX{}, padSizeY{}, stripXSizeY{}, stripYSizeY{};
  array<unsigned int, 16> padOffset{}, stripXOffset{}, stripYOffset{}, padSizeOffset{}, stripXSizeOffset{},
      stripYSizeOffset{};
  array<vector<array<float, 3>>, 4> padTable{}, stripXTable{}, stripYTable{};

  auto nChannels = []( size_t s, const auto& gridX, const auto& gridY ) {
    return [s, &gridX, &gridY]( auto tot, const auto r ) { return tot + gridX[4 * s + r] * gridY[4 * s + r]; };
  };

  for ( int s = 0; s < nStations; ++s ) {
    padTable[s].resize( 48 * ( padGridX[s] * padGridY[s] ) );
    stripXTable[s].resize( 12 * accumulate( views::ints( 0, 4 ), 0, nChannels( s, stripXGridX, stripXGridY ) ) );
    stripYTable[s].resize( 12 * accumulate( views::ints( 0, 4 ), 0, nChannels( s, stripYGridX, stripYGridY ) ) );
  }

  for ( auto& [sizeX, sizeY, offset, gridY] :
        {make_tuple( std::ref( padSizeX ), std::ref( padSizeY ), std::ref( padSizeOffset ), std::ref( padGridY ) ),
         make_tuple( std::ref( stripXSizeX ), std::ref( stripXSizeY ), std::ref( stripXSizeOffset ),
                     std::ref( stripXGridY ) ),
         make_tuple( std::ref( stripYSizeX ), std::ref( stripYSizeY ), std::ref( stripYSizeOffset ),
                     std::ref( stripYGridY ) )} ) {
    sizeX.resize( 24 * accumulate( gridY, 0 ) );
    sizeY.resize( 24 * accumulate( gridY, 0 ) );
    for ( size_t i = 0; i < gridY.size() - 1; ++i ) { offset[i + 1] = offset[i] + 24 * gridY[i]; }
  }

  StatusCode sc = StatusCode::SUCCESS;

  double xp = 0.f, dx = 0.f, yp = 0.f, dy = 0.f, zp = 0.f, dz = 0.f;

  string padType{"pad"}, stripXType{"stripX"}, stripYType{"stripY"};
  // Pads
  auto pad = std::tie( padType, padGridX, padGridY, padSizeX, padSizeY, padOffset, padSizeOffset, padTable );
  // X strips
  auto stripX = std::tie( stripXType, stripXGridX, stripXGridY, stripXSizeX, stripXSizeY, stripXOffset,
                          stripXSizeOffset, stripXTable );
  // Y strips
  auto stripY = std::tie( stripYType, stripYGridX, stripYGridY, stripYSizeX, stripYSizeY, stripYOffset,
                          stripYSizeOffset, stripYTable );

  boost::format info_output{"%|s| %|8d| %|d| %|d| %|d| "
                            "%|2d| %|2d| %|2d| %|2d| %|2d| "
                            "%|5d| %|9.3f| %|9.3f| %|9.3f| %|7.3f| %|7.3f| %|5d|"};

  DumpUtils::Writer output{};
  for ( auto& [t, gridX, gridY, sizeX, sizeY, offset, sizeOffset, table] : {pad, stripX, stripY} ) {
    for ( auto station : views::ints( 0, nStations ) ) {
      size_t index = 0;
      for ( auto region : views::ints( 0, nRegions ) ) {
        size_t gidx  = station * 4 + region;
        offset[gidx] = index;

        auto yxRange = views::concat(
            views::cartesian_product( views::ints( 0, gridY[gidx] ), views::ints( gridX[gidx], 2 * gridX[gidx] ) ),
            views::cartesian_product( views::ints( gridY[gidx], 2 * gridY[gidx] ),
                                      views::ints( 0, 2 * gridX[gidx] ) ) );
        // loop over quarters
        for ( auto [quarter, yx] : views::cartesian_product( views::ints( 0, 4 ), yxRange ) ) {
          auto [y, x] = yx;
          LHCb::MuonTileID tile{
              station, MuonLayout{static_cast<unsigned int>( gridX[gidx] ), static_cast<unsigned int>( gridY[gidx] )},
              region,  quarter,
              x,       y};
          auto sc = det.Tile2XYZ( tile, xp, dx, yp, dy, zp, dz );
          if ( sc.isFailure() ) {
            std::stringstream e;
            e << t << " " << station << " " << region << " " << quarter << " " << gridX[gidx] << " " << gridY[gidx]
              << " " << x << " " << y << "\n";
            throw GaudiException{e.str(), name(), sc};
          } else {
            auto sizeIdx = MuonUtils::size_index( sizeOffset, gridX, gridY, tile );
            if ( UNLIKELY( msgLevel( MSG::VERBOSE ) ) ) {
              verbose() << ( info_output % t % static_cast<unsigned int>( tile ) % station % region % quarter % gidx %
                             gridX[gidx] % gridY[gidx] % x % y % index % xp % yp % zp % dx % dy % sizeIdx )
                        << endmsg;
            }

            // positions are always indexed by station
            table[station][index++] = {numeric_cast<float>( xp ), numeric_cast<float>( yp ), numeric_cast<float>( zp )};

            // sizes are specially indexed
            if ( dx > sizeX[sizeIdx] ) sizeX[sizeIdx] = dx;
            if ( dy > sizeY[sizeIdx] ) sizeY[sizeIdx] = dy;
          }
        }
      }
    }

    output.write( gridX.size(), gridX, gridY.size(), gridY, sizeX.size(), sizeX, sizeY.size(), sizeY, offset.size(),
                  offset, table.size() );
    for ( const auto& station : table ) {
      output.write( station.size() );
      for ( const auto& point : station ) { output.write( point ); }
    }
  }

  return {{std::tuple{output.buffer(), "muon_table", Allen::NonEventData::MuonLookupTables::id}}};
}
