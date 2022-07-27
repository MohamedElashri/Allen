/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <algorithm>
#include <cstdio>
#include "MuonTileID.cuh"
#include "MuonLayout.cuh"
#include "MuonDefinitions.cuh"

namespace Muon {
  class MuonTables {
  public:
    unsigned int m_version;

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

    __device__ MuonTables(size_t* allOffsets, char* dev_muon_tables_raw, unsigned int* sizeOffset_, const int version)
    {
      m_version = version;

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

    __device__ unsigned int getVersion() const { return m_version; }

    MuonTables() = default;
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

  __device__ inline std::array<Muon::MuonLayout, 2> getLayout(MuonTables* muonTables, const Muon::MuonTileID& tile)
  {

    const auto x1 = getLayoutX(muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
    const auto y1 = getLayoutY(muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
    const auto x2 = getLayoutX(muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
    const auto y2 = getLayoutY(muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
    return x1 > x2 ? std::array<Muon::MuonLayout, 2> {Muon::MuonLayout {x1, y1}, Muon::MuonLayout {x2, y2}} :
                     std::array<Muon::MuonLayout, 2> {Muon::MuonLayout {x2, y2}, Muon::MuonLayout {x1, y1}};
  }

  __device__ inline size_t
  lookup_index(MuonTables* muonTables, size_t tableNumber, const Muon::MuonTileID& tile, unsigned int index)
  {
    const size_t idx = Constants::n_regions * tile.station() + tile.region();
    const int xpad = (int) tile.nX();
    const int ypad = (int) tile.nY();
    if (ypad < muonTables->gridY[tableNumber][idx]) {
      index = index + muonTables->gridX[tableNumber][idx] * ypad + xpad - muonTables->gridX[tableNumber][idx];
    }
    else {
      index = index + muonTables->gridX[tableNumber][idx] * muonTables->gridY[tableNumber][idx] +
              2 * muonTables->gridX[tableNumber][idx] * (ypad - muonTables->gridY[tableNumber][idx]) + xpad;
    }
    return index * MuonTables::n_dimensions;
  }

  __device__ inline size_t size_index(MuonTables* muonTables, size_t tableNumber, const Muon::MuonTileID& tile)
  {
    const auto idx = Constants::n_regions * tile.station() + tile.region();
    const auto index = muonTables->sizeOffset[tableNumber * Constants::n_stations * Constants::n_regions + idx] +
                       tile.quarter() * muonTables->gridY[tableNumber][idx] * 6;
    if (tile.nY() < static_cast<unsigned int>(muonTables->gridY[tableNumber][idx])) {
      assert(static_cast<int>(tile.nX()) >= muonTables->gridX[tableNumber][idx]);
      assert(muonTables->gridX[tableNumber][idx] > 0);
      return index + 2 * tile.nY() +
             2 * (tile.nX() - muonTables->gridX[tableNumber][idx]) / muonTables->gridX[tableNumber][idx];
    }
    else {
      assert(muonTables->gridX[tableNumber][idx] > 0);
      return index + 4 * tile.nY() - 2 * muonTables->gridY[tableNumber][idx] +
             (2 * tile.nX() / muonTables->gridX[tableNumber][idx]);
    }
  }

  __device__ inline unsigned int pad_offset(MuonTables* muonTables, const Muon::MuonTileID& tile)
  {
    const auto idx = Constants::n_regions * tile.station() + tile.region();
    const int perQuarter =
      3 * muonTables->gridX[MuonTables::padTableNumber][idx] * muonTables->gridY[MuonTables::padTableNumber][idx];
    unsigned int pad_offset;

    if (muonTables->getVersion() == 2)
      pad_offset = (4 * tile.region() + tile.quarter()) * perQuarter;
    else
      pad_offset = muonTables->offset[MuonTables::padTableNumber][idx] + tile.quarter() * perQuarter;

    return pad_offset;
  }

  __device__ inline unsigned int strip_x_offset(MuonTables* muonTables, const Muon::MuonTileID& tile)
  {
    const auto idx = Constants::n_regions * tile.station() + tile.region();
    const int perQuarter =
      3 * muonTables->gridX[MuonTables::stripXTableNumber][idx] * muonTables->gridY[MuonTables::stripXTableNumber][idx];
    return muonTables->offset[MuonTables::stripXTableNumber][idx] + tile.quarter() * perQuarter;
  }

  __device__ inline unsigned int strip_y_offset(MuonTables* muonTables, const Muon::MuonTileID& tile)
  {
    const auto idx = Constants::n_regions * tile.station() + tile.region();
    const int perQuarter =
      3 * muonTables->gridX[MuonTables::stripYTableNumber][idx] * muonTables->gridY[MuonTables::stripYTableNumber][idx];
    return muonTables->offset[MuonTables::stripYTableNumber][idx] + tile.quarter() * perQuarter;
  }

  __device__ inline void calcPos(
    MuonTables* muonTables,
    size_t tableNumber,
    const Muon::MuonTileID& tile,
    unsigned int offset_index,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z)
  {
    const int station = tile.station();
    const auto index = lookup_index(muonTables, tableNumber, tile, offset_index);

    x = muonTables->coordinates[tableNumber * Constants::n_stations + station][index];
    y = muonTables->coordinates[tableNumber * Constants::n_stations + station][index + 1];
    z = muonTables->coordinates[tableNumber * Constants::n_stations + station][index + 2];

    const auto dxi = size_index(muonTables, tableNumber, tile);
    deltax = muonTables->sizeX[tableNumber][dxi];
    deltay = muonTables->sizeY[tableNumber][dxi];
  }

  __device__ inline void calcTilePos(
    MuonTables* muonTables,
    const Muon::MuonTileID& tile,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z)
  {
    calcPos(muonTables, MuonTables::padTableNumber, tile, pad_offset(muonTables, tile), x, deltax, y, deltay, z);
  }

  __device__ inline void calcStripXPos(
    MuonTables* muonTables,
    const Muon::MuonTileID& tile,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z)
  {
    calcPos(muonTables, MuonTables::stripXTableNumber, tile, strip_x_offset(muonTables, tile), x, deltax, y, deltay, z);
  }

  __device__ inline void calcStripYPos(
    MuonTables* muonTables,
    const Muon::MuonTileID& tile,
    float& x,
    float& deltax,
    float& y,
    float& deltay,
    float& z)
  {
    calcPos(muonTables, MuonTables::stripYTableNumber, tile, strip_y_offset(muonTables, tile), x, deltax, y, deltay, z);
  }
} // namespace Muon
