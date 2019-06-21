#pragma once

#include <algorithm>
#include <cstdio>
#include "MuonTileID.cuh"
#include "MuonLayout.cuh"
#include "MuonDefinitions.cuh"

namespace Muon {
  class MuonTables {
  public:
    static constexpr size_t padTableNumber = 0;
    static constexpr size_t stripXTableNumber = 1;
    static constexpr size_t stripYTableNumber = 2;
    static constexpr size_t n_tables = 3;
    static constexpr size_t n_dimensions = 3;
    static constexpr size_t tableStationRegionOffset[] = {0,
                                                          Constants::n_stations* Constants::n_regions,
                                                          Constants::n_stations* Constants::n_regions * 2,
                                                          Constants::n_stations* Constants::n_regions* n_tables};
    int* gridX[n_tables];
    int* gridY[n_tables];
    float* sizeX[n_tables];
    float* sizeY[n_tables];
    unsigned int* offset[n_tables];
    unsigned int sizeOffset[Constants::n_stations * Constants::n_regions * n_tables];
    float* coordinates[n_tables * Constants::n_stations];

    MuonTables(size_t* allOffsets, char* dev_muon_tables_raw, unsigned int* sizeOffset_)
    {
      for (size_t i = 0; i < Constants::n_stations * Constants::n_regions * n_tables; i++) {
        sizeOffset[i] = sizeOffset_[i];
      }

      size_t currentAllOffsetsIndex = 0;
      for (size_t currentTableNumber = 0; currentTableNumber < n_tables; currentTableNumber++) {
        gridX[currentTableNumber] = (int*) (dev_muon_tables_raw + allOffsets[currentAllOffsetsIndex++]);
        gridY[currentTableNumber] = (int*) (dev_muon_tables_raw + allOffsets[currentAllOffsetsIndex++]);
        sizeX[currentTableNumber] = (float*) (dev_muon_tables_raw + allOffsets[currentAllOffsetsIndex++]);
        sizeY[currentTableNumber] = (float*) (dev_muon_tables_raw + allOffsets[currentAllOffsetsIndex++]);
        offset[currentTableNumber] = (unsigned int*) (dev_muon_tables_raw + allOffsets[currentAllOffsetsIndex++]);
        for (size_t currentStation = 0; currentStation < Constants::n_stations; currentStation++) {
          coordinates[currentTableNumber * Constants::n_stations + currentStation] =
            (float*) (dev_muon_tables_raw + allOffsets[currentAllOffsetsIndex++]);
        }
      }
    }

    MuonTables() {}
  };

  __device__ inline unsigned int
  getLayoutX(MuonTables* muonTables, size_t tableNumber, unsigned int station, unsigned int region)
  {
    return static_cast<unsigned int>(muonTables->gridX[tableNumber][station * Constants::n_regions + region]);
  }

  __device__ inline unsigned int
  getLayoutY(MuonTables* muonTables, size_t tableNumber, unsigned int station, unsigned int region)
  {
    return static_cast<unsigned int>(muonTables->gridY[tableNumber][station * Constants::n_regions + region]);
  }

  __device__ void calcPos(
    MuonTables* muonTables,
    size_t tableNumber,
    const Muon::MuonTileID& tile,
    unsigned int offset_index,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z);

  __device__ void calcTilePos(
    MuonTables* muonTables,
    const Muon::MuonTileID& tile,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z);

  __device__ void calcStripXPos(
    MuonTables* muonTables,
    const Muon::MuonTileID& tile,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z);

  __device__ void calcStripYPos(
    MuonTables* muonTables,
    const Muon::MuonTileID& tile,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z);
} // namespace Muon
