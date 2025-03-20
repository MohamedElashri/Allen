/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>
#include <algorithm>
#include <cmath>
#include <limits>

#include <range/v3/view/repeat_n.hpp>
#include "range/v3/range/conversion.hpp"

#include <DetDesc/GenericConditionAccessorHolder.h>
#include <Kernel/IUTReadoutTool.h>
#include <Kernel/UTTell1Board.h> //v4
#include <Kernel/UTDAQBoard.h>   //v5
#include <UTDet/DeUTDetector.h>
#include <Dumpers/Utils.h>

#include "Dumper.h"
#include "UTUniqueID.cuh"

namespace {
  using std::vector;

  using namespace ranges;

  /// get allen ut sector index
  inline int get_allen_ut_sector_index(const DeUTSector& ut_sector)
  {
    const auto ch = ut_sector.elementID();
    const auto side = ch.side();
    const auto layer = ch.layer();
    const auto stave = ch.stave();
    const auto face = ch.face();
    const auto module = ch.module();
    const auto sector = ch.sector();

    return sector_unique_id(side, layer, stave, face, module, sector);
  }

#ifdef USE_DD4HEP
  const static std::string readoutLocation = "/world/BeforeMagnetRegion/UT:ReadoutMap";
#else
  const static std::string readoutLocation = "/dd/Conditions/ReadoutConf/UT/ReadoutMap";
#endif
} // namespace

namespace {
  struct Geometry {

    Geometry() = default;

    Geometry(std::vector<char>& data, const DeUTDetector& det)
    {
      DumpUtils::Writer output {};

      // To ensure backward compatibility, we use first 16 bits to store UT geometry version
      // and the last 16 bits to store the number of sectors:
      // For old UT geometry which uses 32 bits to store number of sectors, the first 16 bits
      // are always empty, so the version is always zero
      uint32_t number_of_sectors = det.nSectors();
      uint32_t version = 1u; // 0 -> hardcoded dxdy, 1 -> per-serctor dxdy
      uint32_t metadata = number_of_sectors | (version << 16);

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
      vector<float> dxDy;

      pitch.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      cos.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      dy.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      dp0diX.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      dp0diY.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      dp0diZ.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      p0X.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      p0Y.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      p0Z.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());
      dxDy.resize(number_of_sectors, std::numeric_limits<float>::quiet_NaN());

      det.applyToAllSectors([&](DeUTSector const& sector) {
        const auto idx = get_allen_ut_sector_index(sector);
        pitch[idx] = sector.pitch();
        cos[idx] = (sector.cosAngle());
        dy[idx] = (sector.get_dy());
        const auto dp0di = sector.get_dp0di();
        dp0diX[idx] = (dp0di.x());
        dp0diY[idx] = (dp0di.y());
        dp0diZ[idx] = (dp0di.z());
        const auto p0 = sector.get_p0();
        p0X[idx] = (p0.x());
        p0Y[idx] = (p0.y());
        // hack: since p0z is always positive, we can use the signbit to encode whether or not to "stripflip"
        p0Z[idx] = (((sector.xInverted() && sector.getStripflip()) ? -1 : 1) * p0.z());
        // this hack will be used in UTClusterAndPreDecode.cu
        dxDy[idx] = sector.get_dxdy();
      });

      // cross check
      assert(std::all_of(pitch.begin(), pitch.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(cos.begin(), cos.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(dy.begin(), dy.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(dp0diX.begin(), dp0diX.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(dp0diY.begin(), dp0diY.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(dp0diZ.begin(), dp0diZ.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(p0X.begin(), p0X.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(p0Y.begin(), p0Y.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(p0Z.begin(), p0Z.end(), [](auto i) { return !std::isnan(i); }));
      assert(std::all_of(dxDy.begin(), dxDy.end(), [](auto i) { return !std::isnan(i); }));

      output.write(metadata, firstStrip, pitch, dy, dp0diX, dp0diY, dp0diZ, p0X, p0Y, p0Z, cos, dxDy);

      data = output.buffer();
    }
  };

  struct Boards {

    Boards() = default;

    Boards(
      std::vector<char>& data,
      IUTReadoutTool const& readout,
      IUTReadoutTool::ReadoutInfo const* roInfo,
      nlohmann::json const& readoutMap)
    {
      DumpUtils::Writer output {};

      vector<uint32_t> stripsPerHybrids;
      vector<uint32_t> sectors;
      vector<uint32_t> modules;
      vector<uint32_t> faces;
      vector<uint32_t> staves;
      vector<uint32_t> layers;
      vector<uint32_t> sides;
      vector<uint32_t> types;
      vector<uint32_t> chanIDs;

      UTDAQ::version UT_version; // Kernel/UTDAQDefinitions.h
      constexpr uint32_t n_lanes_max = 6;
      // mstahl: this is the condition for the new UT geometry. we might want a version field in the readout map
      if (readoutMap.contains("nTell40InUT"))
        UT_version = UTDAQ::version::v5;
      else if (readoutMap.contains("hybridsPerBoard"))
        UT_version = UTDAQ::version::v4;
      else
        throw GaudiException {
          "Cannot parse UT geometry version from ReadoutMap.", "DumpUTGeometry::Boards", StatusCode::FAILURE};
      // things that (might) depend on the decoding version
      const bool geometry_v5 = UT_version == UTDAQ::version::v5;
      const auto stripsPerHybrid = geometry_v5 ? UTDAQ::nStripsPerBoard / n_lanes_max :
                                                 UTDAQ::nStripsPerBoard / readoutMap["hybridsPerBoard"].get<int>();

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
            sectors.push_back(s.sector());
            modules.push_back(s.module());
            faces.push_back(s.face());
            staves.push_back(s.stave());
            layers.push_back(s.layer());
            sides.push_back(s.side());
            types.push_back(s.type());
            chanIDs.push_back(s.channelID());
          }
          // If the number of lanes is less than 6, fill the remaining ones up to 6 with zeros
          // this is necessary to be compatible with the Allen UT boards layout
          for (uint32_t dummy_lane = n_lanes_in_this_sector; dummy_lane < n_lanes_max; ++dummy_lane) {
            sectors.push_back(0);
            modules.push_back(0);
            faces.push_back(0);
            staves.push_back(0);
            layers.push_back(0);
            sides.push_back(0);
            types.push_back(0);
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
              sectors.push_back(0);
              modules.push_back(0);
              faces.push_back(0);
              staves.push_back(0);
              layers.push_back(0);
              sides.push_back(0);
              types.push_back(0);
              chanIDs.push_back(0);
            }
          }

          stripsPerHybrids.push_back(stripsPerHybrid);

          for (auto is = 0u; is < b->nSectors(); ++is) {
            auto s = std::get<0>(b->DAQToOfflineFull(
              0, UT_version, is * stripsPerHybrid)); // UTTell1Board::ExpandedChannelID (Kernel/UTTell1Board.h)
            sectors.push_back(s.sector);
            modules.push_back(s.module);
            faces.push_back(s.face);
            staves.push_back(s.stave);
            layers.push_back(s.layer);
            sides.push_back(s.side);
            types.push_back(s.type);
            chanIDs.push_back(s.chanID);
          }
          // If the number of sectors is less than 6, fill the remaining ones up to 6 with zeros
          // this is necessary to be compatible with the Allen UT boards layout
          for (auto is = b->nSectors(); is < n_lanes_max; ++is) {
            sectors.push_back(0);
            modules.push_back(0);
            faces.push_back(0);
            staves.push_back(0);
            layers.push_back(0);
            sides.push_back(0);
            types.push_back(0);
            chanIDs.push_back(0);
          }
          ++currentBoardID;
        } // geometry version
      }   // end loop boards

      output.write(
        currentBoardID,
        static_cast<uint32_t>(UT_version),
        stripsPerHybrids,
        sectors,
        modules,
        faces,
        staves,
        layers,
        sides,
        types,
        chanIDs);

      data = output.buffer();
    }
  };

} // namespace

class DumpUTGeometry final
  : public Allen::Dumpers::
      Dumper<void(Geometry const&, Boards const&), LHCb::Algorithm::Traits::usesConditions<Geometry, Boards>> {
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
    {KeyValue {"UTGeomLocation", location(name, "geometry")}, KeyValue {"UTBoardsLocation", location(name, "boards")}})
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
      [&](IUTReadoutTool::ReadoutInfo const& roInfo, nlohmann::json const& readoutMap) {
        Boards boards {m_boardsData, *m_readoutTool, &roInfo, readoutMap};
        dump();
        return boards;
      });
  });
}

void DumpUTGeometry::operator()(Geometry const&, Boards const&) const {}
