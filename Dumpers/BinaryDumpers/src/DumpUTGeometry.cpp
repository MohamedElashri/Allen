/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

#include <range/v3/view/repeat_n.hpp>
#include "range/v3/range/conversion.hpp"

#include <yaml-cpp/yaml.h>

#include <DetDesc/GenericConditionAccessorHolder.h>
#include <Kernel/IUTReadoutTool.h>
#include <Kernel/UTTell1Board.h> //v4
#include <Kernel/UTDAQBoard.h>   //v5
#include <UTDet/DeUTDetector.h>
#include <Dumpers/Utils.h>

#include "Dumper.h"

namespace {
  using std::vector;

  using namespace ranges;

  const static std::string readoutLocation = "/dd/Conditions/ReadoutConf/UT/ReadoutMap";
} // namespace

namespace {
  struct Geometry {

    Geometry() = default;

    Geometry(std::vector<char>& data, const DeUTDetector& det)
    {
      DumpUtils::Writer output {};

      uint32_t number_of_sectors = det.nSectors();
      // first strip is always 1
      vector<uint32_t> firstStrip = views::repeat_n(1, number_of_sectors) | to<std::vector<uint32_t>>();
      vector<float> pitch;
      vector<float> cos;
      vector<float> dy;
      vector<float> dp0diX;
      vector<float> dp0diY;
      vector<float> dp0diZ;
      vector<float> p0X;
      vector<float> p0Y;
      vector<float> p0Z;

      pitch.reserve(number_of_sectors);
      cos.reserve(number_of_sectors);
      dy.reserve(number_of_sectors);
      dp0diX.reserve(number_of_sectors);
      dp0diY.reserve(number_of_sectors);
      dp0diZ.reserve(number_of_sectors);
      p0X.reserve(number_of_sectors);
      p0Y.reserve(number_of_sectors);
      p0Z.reserve(number_of_sectors);

      det.applyToAllSectors([&](DeUTSector const& sector) {
        pitch.push_back(sector.pitch());
        cos.push_back(sector.cosAngle());
        dy.push_back(sector.get_dy());
        const auto dp0di = sector.get_dp0di();
        dp0diX.push_back(dp0di.x());
        dp0diY.push_back(dp0di.y());
        dp0diZ.push_back(dp0di.z());
        const auto p0 = sector.get_p0();
        p0X.push_back(p0.x());
        p0Y.push_back(p0.y());
        // hack: since p0z is always positive, we can use the signbit to encode whether or not to "stripflip"
        p0Z.push_back(((sector.xInverted() && sector.getStripflip()) ? -1 : 1) * p0.z());
        // this hack will be used in UTPreDecode.cu and UTDecodeRawBanksInOrder.cu
      });

      output.write(number_of_sectors, firstStrip, pitch, dy, dp0diX, dp0diY, dp0diZ, p0X, p0Y, p0Z, cos);

      data = output.buffer();
    }
  };

  struct Boards {

    Boards() = default;

    Boards(
      std::vector<char>& data,
      IUTReadoutTool const& readout,
      IUTReadoutTool::ReadoutInfo const* roInfo,
      YAML::Node const& readoutMap)
    {
      DumpUtils::Writer output {};

      vector<uint32_t> stripsPerHybrids;
      vector<uint32_t> stations;
      vector<uint32_t> layers;
      vector<uint32_t> detRegions;
      vector<uint32_t> sectors;
      vector<uint32_t> chanIDs;

      UTDAQ::version UT_version; // Kernel/UTDAQDefinitions.h
      constexpr uint32_t n_lanes_max = 6;
      // mstahl: this is the condition for the new UT geometry. we might want a version field in the readout map
      if (readoutMap["nTell40InUT"].IsDefined())
        UT_version = UTDAQ::version::v5;
      else if (readoutMap["hybridsPerBoard"].IsDefined())
        UT_version = UTDAQ::version::v4;
      else
        throw GaudiException {
          "Cannot parse UT geometry version from ReadoutMap.", "DumpUTGeometry::Boards", StatusCode::FAILURE};
      // things that (might) depend on the decoding version
      const bool geometry_v5 = UT_version == UTDAQ::version::v5;
      const auto stripsPerHybrid = geometry_v5 ? UTDAQ::nStripsPerBoard / n_lanes_max :
                                                 UTDAQ::nStripsPerBoard / readoutMap["hybridsPerBoard"].as<int>();

      uint32_t currentBoardID = 0, cbID = 0;
      for (; cbID < roInfo->nBoards; ++cbID) {
        if (geometry_v5) {
          const auto b = readout.findByDAQOrder(cbID, roInfo); // UTDAQ::Board
          const auto sector_ids = b->sectorIDs();
          stripsPerHybrids.push_back(stripsPerHybrid);
          const auto n_lanes_in_this_sector = sector_ids.size();
          for (typename std::decay<decltype(n_lanes_in_this_sector)>::type lane = 0; lane < n_lanes_in_this_sector;
               ++lane) {                     // old lingo: sectors, new lingo: lanes
            const auto s = sector_ids[lane]; // LHCb::UTChannelID
            stations.push_back(s.station());
            layers.push_back(s.layer());
            detRegions.push_back(s.detRegion());
            sectors.push_back(s.sector());
            chanIDs.push_back(s.channelID());
          }
          // If the number of lanes is less than 6, fill the remaining ones up to 6 with zeros
          // this is necessary to be compatible with the Allen UT boards layout
          for (uint32_t dummy_lane = n_lanes_in_this_sector; dummy_lane < n_lanes_max; ++dummy_lane) {
            stations.push_back(0);
            layers.push_back(0);
            detRegions.push_back(0);
            sectors.push_back(0);
            chanIDs.push_back(0);
          }
          ++currentBoardID;
        }
        else {
          const auto b = readout.findByOrder(cbID, roInfo); // UTTell1Board
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

      output.write(
        currentBoardID,
        static_cast<uint32_t>(UT_version),
        stripsPerHybrids,
        stations,
        layers,
        detRegions,
        sectors,
        chanIDs);

      data = output.buffer();
    }
  };
} // namespace

class DumpUTGeometry final
  : public Allen::Dumpers::
      Dumper<void(Geometry const&, Boards const&), LHCb::DetDesc::usesConditions<Geometry, Boards>> {
public:
  DumpUTGeometry(const std::string& name, ISvcLocator* svcLoc);

  void operator()(Geometry const& geom, Boards const& boards) const override;

  StatusCode initialize() override;

private:
  ToolHandle<IUTReadoutTool> m_readoutTool {this, "UTReadoutTool", "UTReadoutTool"};

  std::vector<char> m_geomData;
  std::vector<char> m_boardsData;
};

DECLARE_COMPONENT(DumpUTGeometry)

DumpUTGeometry::DumpUTGeometry(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(
    name,
    svcLoc,
    {KeyValue {"UTGeomLocation", location(name, "geometry")},
     KeyValue {"UTBoardsLocation", location(name, "boards")}})
{}

StatusCode DumpUTGeometry::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::UTGeometry::id, "ut_geometry", m_geomData);
    addConditionDerivation({DeUTDetLocation::location()}, inputLocation<Geometry>(), [&](DeUTDetector const& det) {
      Geometry geometry {m_geomData, det};
      dump();
      return geometry;
    });

    register_producer(Allen::NonEventData::UTBoards::id, "ut_boards", m_boardsData);
    addConditionDerivation(
      {m_readoutTool->getReadoutInfoKey(), readoutLocation},
      inputLocation<Boards>(),
      [&](IUTReadoutTool::ReadoutInfo const& roInfo, YAML::Node const& readoutMap) {
        Boards boards {m_boardsData, *m_readoutTool, &roInfo, readoutMap};
        dump();
        return boards;
      });
  });
}

void DumpUTGeometry::operator()(Geometry const&, Boards const&) const {}
