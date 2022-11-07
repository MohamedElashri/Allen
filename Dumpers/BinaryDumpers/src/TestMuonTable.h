/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef TESTMUONTABLE_H
#define TESTMUONTABLE_H 1

#include <array>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

// Include files
#include <Event/MuonCoord.h>
#include <Event/ODIN.h>
#include <MuonDet/DeMuonDetector.h>
#include "Event/PrHits.h"
#include <DetDesc/GenericConditionAccessorHolder.h>
#include "LHCbAlgs/Consumer.h"
#include "MuonDet/MuonNamespace.h"

struct MuonTable;
using offset_fun_t = std::function<unsigned int(MuonTable const& table, LHCb::Detector::Muon::TileID const& tile)>;

unsigned int pad_offset(MuonTable const& table, LHCb::Detector::Muon::TileID const& tile);
unsigned int strip_offset(MuonTable const& table, LHCb::Detector::Muon::TileID const& tile);

struct MuonTable {
  MuonTable(offset_fun_t of) : offset_fun {std::move(of)} {}

  void set_geom_version(unsigned int version) { m_geom_version = version; };
  unsigned int get_geom_version() const { return m_geom_version; };

  std::array<int, 16> gridX {}, gridY {};
  std::array<unsigned int, 16> offset {}, sizeOffset {};
  std::vector<float> sizeX {}, sizeY {};
  std::array<std::vector<std::array<float, 3>>, 4> table;
  offset_fun_t offset_fun;
  unsigned int m_geom_version;
};

struct PadTable : public MuonTable {
  PadTable() : MuonTable {pad_offset} {}
};

struct StripTable : public MuonTable {
  StripTable() : MuonTable {strip_offset} {}
};

/** @class TestMuonTable TestMuonTable.h
 *  Algorithm that tests the dumped muon tables
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */

class TestMuonTable final
  : public LHCb::Algorithm::
      Consumer<void(DeMuonDetector const&, MuonHitContainer const&), LHCb::DetDesc::usesConditions<DeMuonDetector>> {
public:
  /// Standard constructor
  TestMuonTable(const std::string& name, ISvcLocator* pSvcLocator) :
    Consumer(
      name,
      pSvcLocator,
      {{"DeMuonLocation", DeMuonLocation::Default}, {"MuonHitsLocation", MuonHitContainerLocation::Default}})
  {}

  StatusCode initialize() override;

  void operator()(DeMuonDetector const&, MuonHitContainer const&) const override;

private:
  Gaudi::Property<std::string> m_table {this, "MuonTable", ""};

  PadTable m_pad;
  StripTable m_stripX;
  StripTable m_stripY;
};
#endif // TESTMUONTABLE_H
