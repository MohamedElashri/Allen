#pragma once

#include "MuonTables.cuh"
#include "MuonRaw.cuh"
#include "MuonGeometry.cuh"
#include "MuonDefinitions.cuh"

static const unsigned int MuonDAQHelper_maxTell1Number = 14;

struct Digit {
  Muon::MuonTileID tile;
  unsigned int     tdc;

  Digit(Muon::MuonTileID tile_, unsigned int tdc_) {
    tile = tile_;
    tdc = tdc_;
  }

  Digit() {}
};

/** @class MuonRawToHits MuonRawToHits.h
 *  This is the muon reconstruction algorithm
 *  This just crosses the logical strips back into pads
 */
class MuonRawToHits {
public:
  MuonRawToHits(Muon::MuonTables* muonTables_, Muon::MuonGeometry* muonGeometry_) {
    muonTables = muonTables_;
    muonGeometry = muonGeometry_;
  }

  MuonRawToHits() {}

  void operator()(Muon::MuonRawEvent& event, Muon::HitsSoA* hitsSoA) const;

private:
  void decodeTileAndTDC(Muon::MuonRawEvent& rawEvent, Digit* storage, size_t* storageOffset) const;

  void makeStripLayouts(unsigned int station, unsigned int region, MuonLayout* layouts) const;

  void addCoordsCrossingMap(Digit* digits, bool* used, size_t startIndex, size_t endIndex, Muon::HitsSoA* hitsSoA,
                            size_t& currentHitIndex) const;

  Muon::MuonTables* muonTables;
public:
  Muon::MuonGeometry* muonGeometry;
};
