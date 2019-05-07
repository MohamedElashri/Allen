#include "MuonTables.cuh"

namespace Muon {
  __constant__ size_t tableStationRegionOffset[] = {
    0,
    Constants::n_stations * Constants::n_regions,
    Constants::n_stations * Constants::n_regions * 2,
    Constants::n_stations * Constants::n_regions * 3
  };
  __constant__ size_t sizeXYOffset[] = {0, 3072, 3072 + 1008, 3072 + 1008 + 3072};
  __constant__ size_t coordinatesOffset[] = {
    MuonTables::n_dimensions * 0,
    MuonTables::n_dimensions * 18432,
    MuonTables::n_dimensions * 18432 * 2,
    MuonTables::n_dimensions * 18432 * 3,
    MuonTables::n_dimensions * 18432 * 4,
    MuonTables::n_dimensions * (18432 * 4 + 4032),
    MuonTables::n_dimensions * (18432 * 4 + 4032 * 2),
    MuonTables::n_dimensions * (18432 * 4 + 4032 * 2 + 2016),
    MuonTables::n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2),
    MuonTables::n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536),
    MuonTables::n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536 * 2),
    MuonTables::n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536 * 2 + 1920),
    MuonTables::n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536 * 2 + 1920 * 2)
  };

  constexpr size_t MuonTables::tableStationRegionOffset[];
  constexpr size_t MuonTables::sizeXYOffset[];
  constexpr size_t MuonTables::coordinatesOffset[];

  __device__ size_t calcIdx(size_t tableNumber, const Muon::MuonTileID& tile) {
    return tableStationRegionOffset[tableNumber] + Constants::n_regions * tile.station() + tile.region();
  }

  __device__ size_t lookup_index(MuonTables* muonTables, size_t tableNumber, const Muon::MuonTileID& tile, unsigned int index) {
    const size_t idx = calcIdx(tableNumber, tile);
    const int xpad = (int) tile.nX();
    const int ypad = (int) tile.nY();
    if (ypad < muonTables->gridY[idx]) {
      index = index + muonTables->gridX[idx] * ypad + xpad - muonTables->gridX[idx];
    } else {
      index = index + muonTables->gridX[idx] * muonTables->gridY[idx] +
              2 * muonTables->gridX[idx] * (ypad - muonTables->gridY[idx]) + xpad;
    }
    return index * MuonTables::n_dimensions;
  }

  __device__ size_t size_index(MuonTables* muonTables, size_t tableNumber, const Muon::MuonTileID& tile) {
    const auto idx = calcIdx(tableNumber, tile);
    const auto index = muonTables->offset[idx] + tile.quarter() * muonTables->gridY[idx] * 6;
    if (tile.nY() < static_cast<unsigned int>( muonTables->gridY[idx] )) {
      return index + 2 * tile.nY() + 2 * (tile.nX() - muonTables->gridX[idx]) / muonTables->gridX[idx];
    } else {
      return index + 4 * tile.nY() - 2 * muonTables->gridY[idx] + (2 * tile.nX() / muonTables->gridX[idx]);
    }
  }

  __device__ unsigned int pad_offset(MuonTables* muonTables, const Muon::MuonTileID& tile) {
    const auto idx = calcIdx(MuonTables::padTableNumber, tile);
    const int perQuarter = 3 * muonTables->gridX[idx] * muonTables->gridY[idx];
    return (4 * tile.region() + tile.quarter()) * perQuarter;
  }

  __device__ unsigned int strip_x_offset(MuonTables* muonTables, const Muon::MuonTileID& tile) {
    const auto idx = calcIdx(MuonTables::stripXTableNumber, tile);
    const int perQuarter = 3 * muonTables->gridX[idx] * muonTables->gridY[idx];
    return muonTables->offset[idx] + tile.quarter() * perQuarter;
  }

  __device__ unsigned int strip_y_offset(MuonTables* muonTables, const Muon::MuonTileID& tile) {
    const auto idx = calcIdx(MuonTables::stripYTableNumber, tile);
    const int perQuarter = 3 * muonTables->gridX[idx] * muonTables->gridY[idx];
    return muonTables->offset[idx] + tile.quarter() * perQuarter;
  }

  __device__ void calcPos(MuonTables* muonTables, size_t tableNumber, Muon::MuonTileID& tile, unsigned int offset_index,
      double& x, double& deltax, double& y, double& deltay, double& z) {
    const int station = tile.station();
    const auto index = coordinatesOffset[tableNumber * Constants::n_stations + station] +
                 lookup_index(muonTables, tableNumber, tile, offset_index);
    x = muonTables->coordinates[index];
    y = muonTables->coordinates[index + 1];
    z = muonTables->coordinates[index + 2];
    const auto dxi = sizeXYOffset[tableNumber] + size_index(muonTables, tableNumber, tile);
    deltax = muonTables->sizeX[dxi];
    deltay = muonTables->sizeY[dxi];
  }

  __device__ void calcTilePos(MuonTables* muonTables, Muon::MuonTileID& tile, double& x, double& deltax,
                   double& y, double& deltay, double& z) {
    calcPos(muonTables, MuonTables::padTableNumber, tile, pad_offset(muonTables, tile), x, deltax, y, deltay, z);
  }

  __device__ void calcStripXPos(MuonTables* muonTables, Muon::MuonTileID& tile, double& x, double& deltax,
                     double& y, double& deltay, double& z) {
    calcPos(muonTables, MuonTables::stripXTableNumber, tile, strip_x_offset(muonTables, tile), x, deltax, y, deltay, z);
  }

  __device__ void calcStripYPos(MuonTables* muonTables, Muon::MuonTileID& tile, double& x, double& deltax,
                     double& y, double& deltay, double& z) {
    calcPos(muonTables, MuonTables::stripYTableNumber, tile, strip_y_offset(muonTables, tile), x, deltax, y, deltay, z);
  }

  void read_muon_tables(const char* raw_input, MuonTables* muonTables) {
    for (size_t tableNumber = 0; tableNumber < MuonTables::n_tables; tableNumber++) {
      size_t gridXSize;
      std::copy_n((size_t*) raw_input, 1, &gridXSize);
      raw_input += sizeof(size_t);
      std::copy_n((int*) raw_input, gridXSize, muonTables->gridX + MuonTables::tableStationRegionOffset[tableNumber]);
      raw_input += sizeof(int) * gridXSize;

      size_t gridYSize;
      std::copy_n((size_t*) raw_input, 1, &gridYSize);
      raw_input += sizeof(size_t);
      std::copy_n((int*) raw_input, gridYSize, muonTables->gridY + MuonTables::tableStationRegionOffset[tableNumber]);
      raw_input += sizeof(int) * gridYSize;

      size_t sizeXSize;
      std::copy_n((size_t*) raw_input, 1, &sizeXSize);
      raw_input += sizeof(size_t);
      std::copy_n((float*) raw_input, sizeXSize, muonTables->sizeX + MuonTables::sizeXYOffset[tableNumber]);
      raw_input += sizeof(float) * sizeXSize;

      size_t sizeYSize;
      std::copy_n((size_t*) raw_input, 1, &sizeYSize);
      raw_input += sizeof(size_t);
      std::copy_n((float*) raw_input, sizeYSize, muonTables->sizeY + MuonTables::sizeXYOffset[tableNumber]);
      raw_input += sizeof(float) * sizeYSize;

      size_t offsetSize;
      std::copy_n((size_t*) raw_input, 1, &offsetSize);
      raw_input += sizeof(size_t);
      std::copy_n((unsigned int*) raw_input, offsetSize,
                  muonTables->offset + MuonTables::tableStationRegionOffset[tableNumber]);
      raw_input += sizeof(unsigned int) * offsetSize;

      muonTables->offset[MuonTables::tableStationRegionOffset[tableNumber]] = 0;
      for (size_t i = 0; i < Constants::n_stations * Constants::n_regions - 1; ++i) {
        size_t index = MuonTables::tableStationRegionOffset[tableNumber] + i;
        muonTables->sizeOffset[index + 1] = muonTables->sizeOffset[index] + 24 * muonTables->gridY[index];
      }

      size_t tableSize;
      std::copy_n((size_t*) raw_input, 1, &tableSize);
      raw_input += sizeof(size_t);

      for (int i = 0; i < tableSize; i++) {
        size_t stationTableSize;
        std::copy_n((size_t*) raw_input, 1, &stationTableSize);
        raw_input += sizeof(size_t);
        for (int j = 0; j < stationTableSize; j++) {
          std::copy_n(
              (float*) raw_input,
              MuonTables::n_dimensions,
              (muonTables->coordinates) + MuonTables::coordinatesOffset[tableNumber * Constants::n_stations + i] +
              MuonTables::n_dimensions * j
          );
          raw_input += sizeof(float) * MuonTables::n_dimensions;
        }
      }
    }
  }
};
