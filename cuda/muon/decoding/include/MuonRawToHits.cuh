#pragma once

#include "MuonTables.cuh"
#include "MuonRaw.cuh"
#include "MuonGeometry.cuh"
#include "MuonDefinitions.cuh"

static const unsigned int MuonDAQHelper_maxTell1Number = 14;

struct Digit {
  Muon::MuonTileID tile;
  unsigned int     tdc;

  __device__ Digit(Muon::MuonTileID tile_, unsigned int tdc_) {
    tile = tile_;
    tdc = tdc_;
  }

  __device__ Digit() {}
};

/** @class MuonRawToHits MuonRawToHits.h
 *  This is the muon reconstruction algorithm
 *  This just crosses the logical strips back into pads
 */
class MuonRawToHits {
public:
  __host__ __device__ MuonRawToHits(Muon::MuonTables muonTables_, Muon::MuonGeometry muonGeometry_) {
    muonTables = muonTables_;
    muonGeometry = muonGeometry_;
  }

  __host__ __device__ MuonRawToHits() {}

  __device__ void operator()(Muon::MuonRawEvent& event, Muon::HitsSoA* hitsSoA) const;

private:
  __device__ void decodeTileAndTDC(Muon::MuonRawEvent& rawEvent, Digit* storage, size_t* storageOffset) const;

  __device__ void makeStripLayouts(unsigned int station, unsigned int region, MuonLayout* layouts) const;

  __device__ void addCoordsCrossingMap(Digit* digits, bool* used, size_t startIndex, size_t endIndex, Muon::HitsSoA* hitsSoA,
                            size_t& currentHitIndex) const;

  Muon::MuonTables muonTables;
public:
  Muon::MuonGeometry muonGeometry;
};
