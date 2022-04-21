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
} // namespace Muon
