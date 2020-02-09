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
#include <GaudiAlg/Consumer.h>
#include <MuonDet/DeMuonDetector.h>

struct MuonTable;
using offset_fun_t = std::function<unsigned int(MuonTable const& table, LHCb::MuonTileID const& tile)>;

unsigned int pad_offset(MuonTable const& table, LHCb::MuonTileID const& tile);
unsigned int strip_offset(MuonTable const& table, LHCb::MuonTileID const& tile);

struct MuonTable {
  MuonTable(offset_fun_t of) : offset_fun {std::move(of)} {}

  std::array<int, 16> gridX {}, gridY {};
  std::array<unsigned int, 16> offset {}, sizeOffset {};
  std::vector<float> sizeX {}, sizeY {};
  std::array<std::vector<std::array<float, 3>>, 4> table;
  offset_fun_t offset_fun;
};

struct PadTable : public MuonTable {
  PadTable() : MuonTable {pad_offset} {}
};

struct StripTable : public MuonTable {
  StripTable() : MuonTable {strip_offset} {}
};

/** @class TestMuonTable TestMuonTable.h
 *  Algorithm that dumps FT hit variables to binary files.
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class TestMuonTable : public Gaudi::Functional::Consumer<void(const LHCb::MuonCoords&)> {
public:
  /// Standard constructor
  TestMuonTable(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  void operator()(const LHCb::MuonCoords&) const override;

private:
  Gaudi::Property<std::string> m_table {this, "MuonTable", ""};

  PadTable m_pad;
  StripTable m_stripX;
  StripTable m_stripY;

  DeMuonDetector* m_det = nullptr;
};
#endif // TESTMUONTABLE_H
