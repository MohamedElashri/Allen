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
  class MuonRawToHits {
  public:
    MuonRawToHits(MuonTables muonTables_, MuonGeometry muonGeometry_) {
      muonTables = muonTables_;
      muonGeometry = muonGeometry_;
    }

    __device__ MuonRawToHits() {}

    __device__ void operator()(MuonRawEvent& event, HitsSoA* hitsSoA) const;

  private:
    __device__ void decodeTileAndTDC(MuonRawEvent& rawEvent, Digit* storage, size_t* storageOffset) const;

    __device__ void makeStripLayouts(unsigned int station, unsigned int region, MuonLayout* layouts) const;

    __device__ void addCoordsCrossingMap(Digit* digits, bool* used, size_t startIndex, size_t endIndex,
        HitsSoA* hitsSoA, size_t& currentHitIndex) const;

    MuonTables muonTables;
    MuonGeometry muonGeometry;
  };
}