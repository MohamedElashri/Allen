/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <boost/filesystem.hpp>
#include <string>

#include "Utils.h"

namespace {
  namespace fs = boost::filesystem;
}

bool DumpUtils::createDirectory(fs::path directory)
{
  if (!fs::exists(directory)) {
    boost::system::error_code ec;
    bool success = fs::create_directories(directory, ec);
    success &= !ec;
    return success;
  }
  return true;
}

size_t MuonUtils::size_index(
  std::array<unsigned int, 16> const& offset,
  std::array<int, 16> const& gridX,
  std::array<int, 16> const& gridY,
  LHCb::MuonTileID const& tile)
{
  auto idx = 4 * tile.station() + tile.region();
  auto index = offset[idx] + tile.quarter() * gridY[idx] * 6;
  if (tile.nY() < static_cast<unsigned int>(gridY[idx])) {
    return index + 2 * tile.nY() + 2 * (tile.nX() - gridX[idx]) / gridX[idx];
  }
  else {
    return index + 4 * tile.nY() - 2 * gridY[idx] + (2 * tile.nX() / gridX[idx]);
  }
}
