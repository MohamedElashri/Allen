/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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

  struct MuonRawToHits {
    MuonTables* muonTables;
    MuonGeometry* muonGeometry;
  };

  __device__ inline unsigned regionAndQuarter(const Digit& i)
  {
    return i.tile.region() * Constants::n_quarters + i.tile.quarter();
  }
} // namespace Muon
