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

    __device__ Hit(HitsSoA* hitsSoA, uint index);

    __device__ Hit() {}
  };

  __device__ void setAtIndex(HitsSoA* hitsSoA, uint index, int tile, float x, float dx, float y, float dy,
      float z, float dz, int uncrossed, unsigned int time, int delta_time, int cluster_size, int region);

  __device__ void setAtIndex(HitsSoA* hitsSoA, uint index, Hit* hit);

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

    __device__ void addCoordsCrossingMap(unsigned int* tileIds, unsigned int* tdcValues, bool* used, uint startIndex,
        uint endIndex, HitsSoA* hitsSoA, uint& currentHitIndex) const;

    __device__ void makeStripLayouts(unsigned int station, unsigned int region, MuonLayout* layouts) const;
  };
}
