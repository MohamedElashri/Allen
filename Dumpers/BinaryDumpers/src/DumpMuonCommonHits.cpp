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

#include "DumpMuonCommonHits.h"
#include "Utils.h"

namespace {
  using std::string;
  using std::to_string;
  using std::vector;

  namespace fs = boost::filesystem;
} // namespace

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(DumpMuonCommonHits)

DumpMuonCommonHits::DumpMuonCommonHits(const string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"ODINLocation", LHCb::ODINLocation::Default},
     KeyValue {"MuonHitHandler", MuonHitContainerLocation::Default}})
{}

StatusCode DumpMuonCommonHits::initialize()
{
  if (!DumpUtils::createDirectory(m_outputDirectory.value())) {
    error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
    return StatusCode::FAILURE;
  }
  return StatusCode::SUCCESS;
}

void DumpMuonCommonHits::operator()(const LHCb::ODIN& odin, const MuonHitContainer& hitHandler) const
{

  /*Write muon common hit variables for GPU to binary file */
  DumpUtils::FileWriter outfile {m_outputDirectory.value() + "/" + to_string(odin.runNumber()) + "_" +
                                 to_string(odin.eventNumber()) + ".bin"};

  const int n_stations = 4;

  auto tileID = std::array<vector<int>, n_stations> {};
  auto x = std::array<vector<float>, n_stations> {};
  auto dx = std::array<vector<float>, n_stations> {};
  auto y = std::array<vector<float>, n_stations> {};
  auto dy = std::array<vector<float>, n_stations> {};
  auto z = std::array<vector<float>, n_stations> {};
  auto dz = std::array<vector<float>, n_stations> {};
  auto uncrossed = std::array<vector<int>, n_stations> {};
  auto time = std::array<vector<unsigned int>, n_stations> {};
  auto deltaTime = std::array<vector<int>, n_stations> {};
  auto clusterSize = std::array<vector<int>, n_stations> {};
  auto region = std::array<vector<int>, n_stations> {};

  // loop over the hits in every station
  for (int i_station = 0; i_station < n_stations; ++i_station) {
    for (const auto& hit : hitHandler.hits(i_station)) {
      tileID[i_station].push_back(int(hit.tile()));
      x[i_station].push_back(hit.x());
      dx[i_station].push_back(hit.dx());
      y[i_station].push_back(hit.y());
      dy[i_station].push_back(hit.dy());
      z[i_station].push_back(hit.z());
      dz[i_station].push_back(hit.dz());
      uncrossed[i_station].push_back((int) (hit.uncrossed()));
      time[i_station].push_back(hit.time());
      deltaTime[i_station].push_back(hit.deltaTime());
      clusterSize[i_station].push_back(hit.clusterSize());
      region[i_station].push_back((int) (hit.tile().region()));
    }
  }

  // first the number of hits in every station
  for (int i_station = 0; i_station < n_stations; ++i_station) {
    uint32_t n_hits = (int) (tileID[i_station].size());
    outfile.write(n_hits);
  }

  // then the vectors containing the variables
  for (int i_station = 0; i_station < n_stations; ++i_station) {
    outfile.write(
      tileID[i_station],
      x[i_station],
      dx[i_station],
      y[i_station],
      dy[i_station],
      z[i_station],
      dz[i_station],
      uncrossed[i_station],
      time[i_station],
      deltaTime[i_station],
      clusterSize[i_station],
      region[i_station]);
  }
}
