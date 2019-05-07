#include "MuonRawToHits.cuh"
#include <stdio.h>

namespace Muon {
  __device__ void setAtIndex(HitsSoA* hitsSoA, size_t index, int tile, float x, float dx, float y, float dy,
      float z, float dz, int uncrossed, unsigned int time, int delta_time, int cluster_size, int region) {
    hitsSoA->tile[index] = tile;
    hitsSoA->x[index] = x;
    hitsSoA->dx[index] = dx;
    hitsSoA->y[index] = y;
    hitsSoA->dy[index] = dy;
    hitsSoA->z[index] = z;
    hitsSoA->dz[index] = dz;
    hitsSoA->uncrossed[index] = uncrossed;
    hitsSoA->time[index] = time;
    hitsSoA->delta_time[index] = delta_time;
    hitsSoA->cluster_size[index] = cluster_size;
    hitsSoA->region_id[index] = region;
  }

  __device__ void recalculateNumberOfHitsPerStationAndStationOffsets(HitsSoA* hitsSoA,
      size_t totalNumberOfHits) {
    hitsSoA->station_offsets[0] = 0;
    int currentStation = MuonTileID::station(hitsSoA->tile[0]);
    int initialCurrentStation = currentStation;
    for (int i = 1; i < totalNumberOfHits; i++) {
      auto id = static_cast<unsigned int>(hitsSoA->tile[i]);
      if (MuonTileID::station(id) != currentStation) {
        hitsSoA->station_offsets[currentStation + 1] = i;
        currentStation++;
      }
    }

    for (int j = currentStation; j + 1 < Constants::n_stations; j++) {
      hitsSoA->station_offsets[j + 1] = totalNumberOfHits;
    }
    if (initialCurrentStation == currentStation) {
      for (int j = initialCurrentStation; j + 1 < Constants::n_stations; j++) {
        hitsSoA->station_offsets[j + 1] = totalNumberOfHits;
      }
    }
    for (currentStation = 0; currentStation + 1 < Constants::n_stations; currentStation++) {
      hitsSoA->number_of_hits_per_station[currentStation] =
          hitsSoA->station_offsets[currentStation + 1] - hitsSoA->station_offsets[currentStation];
    }
    hitsSoA->number_of_hits_per_station[Constants::n_stations - 1] =
        totalNumberOfHits - hitsSoA->station_offsets[Constants::n_stations - 1];
  }

  __device__ size_t regionAndQuarter(const Digit& i) {
    return i.tile.region() * Constants::n_quarters + i.tile.quarter();
  }

  __device__ void MuonRawToHits::makeStripLayouts(const unsigned int station, const unsigned int region,
      MuonLayout* layouts) const {
    const unsigned int x1 = getLayoutX((MuonTables*) &muonTables, MuonTables::stripXTableNumber, station, region);
    const unsigned int y1 = getLayoutY((MuonTables*) &muonTables, MuonTables::stripXTableNumber, station, region);
    const unsigned int x2 = getLayoutX((MuonTables*) &muonTables, MuonTables::stripYTableNumber, station, region);
    const unsigned int y2 = getLayoutY((MuonTables*) &muonTables, MuonTables::stripYTableNumber, station, region);
    layouts[x1 > x2] = MuonLayout(x2, y2);
    layouts[x1 <= x2] = MuonLayout(x1, y1);
  }

  __device__ void MuonRawToHits::addCoordsCrossingMap(unsigned int* tileIds, unsigned int* tdcValues, bool* used,
      size_t startIndex, size_t endIndex, HitsSoA* hitsSoA, int& currentHitIndex) const {
    if (startIndex == endIndex) {
      return;
    }
    MuonLayout layouts[2];
    makeStripLayouts(MuonTileID::station(tileIds[startIndex]), MuonTileID::region(tileIds[startIndex]), layouts);
    const MuonLayout& layoutOne = layouts[0];
    const MuonLayout& layoutTwo = layouts[1];
    size_t midIndex = startIndex;
    unsigned int tmpTileId;
    for (size_t i = startIndex; i < endIndex; i++) {
      if (MuonTileID::layout(tileIds[i]) == layoutOne) {
        if (midIndex != i) {
          tmpTileId = tileIds[i];
          tileIds[i] = tileIds[midIndex];
          tileIds[midIndex] = tmpTileId;
        }
        midIndex++;
      }
    }
    const int thisGridX = layoutOne.xGrid();
    const int thisGridY = layoutOne.yGrid();
    const int otherGridX = layoutTwo.xGrid();
    const int otherGridY = layoutTwo.yGrid();
    for (size_t digitsOneIndex = startIndex; digitsOneIndex < midIndex; digitsOneIndex++) {
      const unsigned int keyX = MuonTileID::nX(tileIds[digitsOneIndex]) * otherGridX / thisGridX;
      const unsigned int keyY = MuonTileID::nY(tileIds[digitsOneIndex]);
      for (size_t digitsTwoIndex = midIndex; digitsTwoIndex < endIndex; digitsTwoIndex++) {
        const unsigned int candidateX = MuonTileID::nX(tileIds[digitsTwoIndex]);
        const unsigned int candidateY = MuonTileID::nY(tileIds[digitsTwoIndex]) * thisGridY / otherGridY;
        if (keyX == candidateX && keyY == candidateY) {
          MuonTileID padTile(tileIds[digitsOneIndex]);
          padTile.setY(MuonTileID::nY(tileIds[digitsTwoIndex]));
          padTile.setLayout(MuonLayout(thisGridX, otherGridY));
          double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
          calcTilePos((MuonTables*) &muonTables, padTile, x, dx, y, dy, z);
          const unsigned int uncrossed = 0;
          const int clusterSize = 0;
          const int region = padTile.region();
          const int localCurrentHitIndex = atomicAdd(&currentHitIndex, 1);
          setAtIndex(hitsSoA, localCurrentHitIndex, padTile.id(), x, dx, y, dy, z, dz, uncrossed,
                     tdcValues[digitsOneIndex], tdcValues[digitsOneIndex] - tdcValues[digitsTwoIndex],
                     clusterSize, region);
          used[digitsOneIndex] = used[digitsTwoIndex] = true;
        }
      }
    }

    const size_t startIndices[] = {startIndex, midIndex};
    const size_t endIndices[] = {midIndex, endIndex};
    for (size_t currentDigitsIndex = 0; currentDigitsIndex < 2; currentDigitsIndex++) {
      for (size_t currentDigitIndex = startIndices[currentDigitsIndex];
           currentDigitIndex < endIndices[currentDigitsIndex];
           currentDigitIndex++) {
        if (!used[currentDigitIndex]) {
          double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
          MuonTileID tile = MuonTileID(tileIds[currentDigitIndex]);
          const int region = tile.region();
          if (tile.station() > (Constants::n_stations - 3) && region == 0) {
            calcTilePos((MuonTables*) &muonTables, tile, x, dx, y, dy, z);
          } else {
            if (currentDigitsIndex == 0) {
              calcStripXPos((MuonTables*) &muonTables, tile, x, dx, y, dy, z);
            } else {
              calcStripYPos((MuonTables*) &muonTables, tile, x, dx, y, dy, z);
            }
          }
          const unsigned int uncrossed = 1;
          const int clusterSize = 0;
          const int localCurrentHitIndex = atomicAdd(&currentHitIndex, 1);
          setAtIndex(hitsSoA, localCurrentHitIndex, tile.id(), x, dx, y, dy, z, dz, uncrossed,
                     tdcValues[currentDigitIndex], tdcValues[currentDigitIndex], clusterSize, region);
        }
      }
    }
  }
};
