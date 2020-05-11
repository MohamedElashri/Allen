#pragma once

#include "MuonTables.cuh"
#include "MuonRaw.cuh"
#include "MuonGeometry.cuh"
#include "MuonDefinitions.cuh"

namespace Muon {
  struct Digit {
    MuonTileID tile;
    unsigned int tdc;
  };

  /** @class MuonRawToHits MuonRawToHits.h
   *  This is the muon reconstruction algorithm
   *  This just crosses the logical strips back into pads
   */
  struct MuonRawToHits {
    MuonTables* muonTables;
    MuonGeometry* muonGeometry;
  };

  __device__ inline uint regionAndQuarter(const Digit& i)
  {
    return i.tile.region() * Constants::n_quarters + i.tile.quarter();
  }
} // namespace Muon
