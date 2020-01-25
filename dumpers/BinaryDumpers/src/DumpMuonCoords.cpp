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
#include <vector>

#include <boost/filesystem.hpp>

#include "DumpMuonCoords.h"
#include "Utils.h"

namespace {
  using std::string;
  using std::to_string;
  using std::vector;

  namespace fs = boost::filesystem;
} // namespace

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(DumpMuonCoords)

DumpMuonCoords::DumpMuonCoords(const string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"ODINLocation", LHCb::ODINLocation::Default},
     KeyValue {"MuonCoordsLocation", LHCb::MuonCoordLocation::MuonCoords}})
{}

StatusCode DumpMuonCoords::initialize()
{
  if (!DumpUtils::createDirectory(m_outputDirectory.value())) {
    error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
    return StatusCode::FAILURE;
  }
  return StatusCode::SUCCESS;
}

void DumpMuonCoords::operator()(const LHCb::ODIN& odin, const LHCb::MuonCoords& muonCoords) const
{

  /*Write muon coord variables for GPU to binary file */
  DumpUtils::FileWriter outfile {m_outputDirectory.value() + "/" + to_string(odin.runNumber()) + "_" +
                                 to_string(odin.eventNumber()) + ".bin"};
  constexpr int n_stations_muon = 4;

  auto uncrossed = std::array<std::vector<int>, n_stations_muon> {};
  // if uncrossed is true: digitTile contains one MuonTileID
  // else if crossed pads were found: digitTile contains two MuonTileIDs
  auto digitTile = std::array<std::vector<int>, n_stations_muon> {};
  auto digitTDC1 = std::array<std::vector<unsigned int>, n_stations_muon> {};
  auto digitTDC2 = std::array<std::vector<unsigned int>, n_stations_muon> {};

  std::vector<std::vector<const LHCb::MuonCoord*>> sortedCoords(n_stations_muon);
  for (auto coord : muonCoords) {
    sortedCoords[coord->key().station()].emplace_back(coord);
  }

  for (int station = 0; station < n_stations_muon; station++) {
    for (const auto& coord : sortedCoords[station]) {
      uncrossed[station].push_back((int) (coord->uncrossed()));
      for (LHCb::MuonTileID tileID : coord->digitTile()) {
        digitTile[station].push_back(int(tileID));
      }
      digitTDC1[station].push_back(coord->digitTDC1());
      digitTDC2[station].push_back(coord->digitTDC2());
    }
  }
  // first the number of hits per station
  for (int station = 0; station < n_stations_muon; ++station) {
    uint32_t n_hits = (int) (uncrossed[station].size());
    outfile.write(n_hits);
  }

  // then the vectors containing the variables
  for (int station = 0; station < n_stations_muon; ++station) {
    outfile.write(uncrossed[station], digitTile[station], digitTDC1[station], digitTDC2[station]);
  }
}
