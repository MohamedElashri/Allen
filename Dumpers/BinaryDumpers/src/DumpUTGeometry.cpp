/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
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
#include "range/v3/to_container.hpp"
namespace ranges {
  template<typename C>
  inline constexpr auto to = to_<C>;
}
#else
#include "range/v3/range/conversion.hpp"
#endif

#include <Kernel/IUTReadoutTool.h>
#include <Kernel/UTTell1Board.h> //v4
#include <Kernel/UTDAQBoard.h>   //v5

#include "DumpUTGeometry.h"

namespace {
  using std::vector;

  using namespace ranges;
} // namespace

DECLARE_COMPONENT(DumpUTGeometry)

DumpUtils::Dump DumpUTGeometry::dumpGeom() const
{
  const auto& sectors = detector().sectors();
  uint32_t number_of_sectors = sectors.size();
  // first strip is always 1
  vector<uint32_t> firstStrip = views::repeat_n(1, number_of_sectors) | to<std::vector<uint32_t>>();
  vector<float> pitch = views::transform(sectors, &DeUTSector::pitch) | to<std::vector<float>>();
  vector<float> cos = views::transform(sectors, &DeUTSector::cosAngle) | to<std::vector<float>>();
  vector<float> dy;
  vector<float> dp0diX;
  vector<float> dp0diY;
  vector<float> dp0diZ;
  vector<float> p0X;
  vector<float> p0Y;
  vector<float> p0Z;

  dy.reserve(number_of_sectors);
  dp0diX.reserve(number_of_sectors);
  dp0diY.reserve(number_of_sectors);
  dp0diZ.reserve(number_of_sectors);
  p0X.reserve(number_of_sectors);
  p0Y.reserve(number_of_sectors);
  p0Z.reserve(number_of_sectors);

  for (const auto sector : sectors) { // loop DeUTSector
    dy.push_back(sector->get_dy());
    const auto dp0di = sector->get_dp0di();
    dp0diX.push_back(dp0di.x());
    dp0diY.push_back(dp0di.y());
    dp0diZ.push_back(dp0di.z());
    const auto p0 = sector->get_p0();
    p0X.push_back(p0.x());
    p0Y.push_back(p0.y());
    // hack: since p0z is always positive, we can use the signbit to encode whether or not to "stripflip"
    p0Z.push_back(((sector->xInverted() && sector->getStripflip()) ? -1 : 1) * p0.z());
    // this hack will be used in UTPreDecode.cu and UTDecodeRawBanksInOrder.cu
  }

  DumpUtils::Writer ut_geometry {};
  ut_geometry.write(number_of_sectors, firstStrip, pitch, dy, dp0diX, dp0diY, dp0diZ, p0X, p0Y, p0Z, cos);

  return std::tuple {ut_geometry.buffer(), "ut_geometry", Allen::NonEventData::UTGeometry::id};
}

DumpUtils::Dump DumpUTGeometry::dumpBoards() const
{
  std::vector<uint32_t> stripsPerHybrids;
  std::vector<uint32_t> stations;
  std::vector<uint32_t> layers;
  std::vector<uint32_t> detRegions;
  std::vector<uint32_t> sectors;
  std::vector<uint32_t> chanIDs;

  const auto readout = tool<IUTReadoutTool>("UTReadoutTool");
  if (!readout) throw GaudiException {"Failed to obtain readout tool.", name(), StatusCode::FAILURE};

  // Strips per hybrid cannot be obtained from the boards, so use the
  // condition where it came from instead.
  // This can be found in UTReadoutTool
  Condition* rInfo = getDet<Condition>("/dd/Conditions/ReadoutConf/UT/ReadoutMap");

  UTDAQ::version UT_version; // Kernel/UTDAQDefinitions.h
  constexpr uint32_t n_lanes_max = 6;
  // mstahl: this is the condition for the new UT geometry. we might want a version field in the readout map
  if (rInfo->exists("nTell40InUT"))
    UT_version = UTDAQ::version::v5;
  else if (rInfo->exists("hybridsPerBoard"))
    UT_version = UTDAQ::version::v4;
  else
    throw GaudiException {"Cannot parse UT geometry version from ReadoutMap.", name(), StatusCode::FAILURE};
  // things that (might) depend on the decoding version
  const bool geometry_v5 = UT_version == UTDAQ::version::v5;
  const auto stripsPerHybrid =
    geometry_v5 ? UTDAQ::nStripsPerBoard / n_lanes_max : UTDAQ::nStripsPerBoard / rInfo->param<int>("hybridsPerBoard");
  const auto n_boards = geometry_v5 ? rInfo->param<int>("nTell40InUT") * 2 : readout->nBoard();

  uint32_t currentBoardID = 0, cbID = 0;
  for (; cbID < n_boards;
       ++cbID) { // In v5 there are no gaps in the numbering, so that the readouttool will always find a board
    if (geometry_v5) {
      const auto b = readout->findByDAQOrder(cbID); // UTDAQ::Board
      const auto sector_ids = b->sectorIDs();
      stripsPerHybrids.push_back(stripsPerHybrid);
      for (unsigned lane = 0; lane < n_lanes_max; ++lane) { // old lingo: sectors, new lingo: lanes
        const auto s = sector_ids[lane];                    // LHCb::UTChannelID
        stations.push_back(s.station());
        layers.push_back(s.layer());
        detRegions.push_back(s.detRegion());
        sectors.push_back(s.sector());
        chanIDs.push_back(s.channelID());
      }
      ++currentBoardID;
    }
    else {
      const auto b = readout->findByOrder(cbID); // UTTell1Board
      const auto boardID = b->boardID().id();
      // Insert empty boards if there is a gap between the last boardID and the
      // current one
      for (; boardID != 0 && currentBoardID < boardID; ++currentBoardID) {
        stripsPerHybrids.push_back(0);
        for (auto i = 0u; i < n_lanes_max; ++i) {
          stations.push_back(0);
          layers.push_back(0);
          detRegions.push_back(0);
          sectors.push_back(0);
          chanIDs.push_back(0);
        }
      }

      stripsPerHybrids.push_back(stripsPerHybrid);

      for (auto is = 0u; is < b->nSectors(); ++is) {
        auto s = std::get<0>(b->DAQToOfflineFull(
          0, UT_version, is * stripsPerHybrid)); // UTTell1Board::ExpandedChannelID (Kernel/UTTell1Board.h)
        stations.push_back(s.station);
        layers.push_back(s.layer);
        detRegions.push_back(s.detRegion);
        sectors.push_back(s.sector);
        chanIDs.push_back(s.chanID);
      }
      // If the number of sectors is less than 6, fill the remaining ones up to 6 with zeros
      // this is necessary to be compatible with the Allen UT boards layout
      for (auto is = b->nSectors(); is < n_lanes_max; ++is) {
        stations.push_back(0);
        layers.push_back(0);
        detRegions.push_back(0);
        sectors.push_back(0);
        chanIDs.push_back(0);
      }
      ++currentBoardID;
    } // geometry version
  }   // end loop boards

  DumpUtils::Writer ut_boards {};
  ut_boards.write(currentBoardID, stripsPerHybrids, stations, layers, detRegions, sectors, chanIDs);

  return std::tuple {ut_boards.buffer(), "ut_boards", Allen::NonEventData::UTBoards::id};
}

DumpUtils::Dumps DumpUTGeometry::dumpGeometry() const { return {{dumpGeom(), dumpBoards()}}; }
