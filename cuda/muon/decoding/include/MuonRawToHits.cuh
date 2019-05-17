#pragma once

#include "MuonTables.cuh"
#include "MuonRaw.cuh"
#include "MuonGeometry.cuh"
#include "MuonDefinitions.cuh"

namespace Muon {
  struct Hit {
    int tile;
    float x;
    float dx;
    float y;
    float dy;
    float z;
    float dz;
    int uncrossed;
    unsigned int time;
    int delta_time;
    int cluster_size;
    int region;

    __device__ Hit(HitsSoA* hitsSoA, size_t index);

    __device__ Hit() {}
  };

  __device__ void setAtIndex(HitsSoA* hitsSoA, size_t index, int tile, float x, float dx, float y, float dy,
      float z, float dz, int uncrossed, unsigned int time, int delta_time, int cluster_size, int region);

  __device__ void setAtIndex(HitsSoA* hitsSoA, size_t index, Hit* hit);

  __device__ void recalculateNumberOfHitsPerStationAndStationOffsets(HitsSoA* hitsSoA, size_t totalNumberOfHits);

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
    MuonTables* muonTables;
    MuonGeometry* muonGeometry;

    __device__ void addCoordsCrossingMap(unsigned int* tileIds, unsigned int* tdcValues, bool* used, size_t startIndex,
        size_t endIndex, HitsSoA* hitsSoA, int& currentHitIndex) const;

  private:
    __device__ void decodeTileAndTDC(MuonRawEvent& rawEvent, Digit* storage, size_t* storageOffset) const;

    __device__ void makeStripLayouts(unsigned int station, unsigned int region, MuonLayout* layouts) const;
  };
}
