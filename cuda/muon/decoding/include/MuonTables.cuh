#pragma once

#include <algorithm>

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
    static constexpr size_t tableStationRegionOffset[] = {
        0,
        Constants::n_stations * Constants::n_regions,
        Constants::n_stations * Constants::n_regions * 2,
        Constants::n_stations * Constants::n_regions * n_tables
    };
    static constexpr size_t sizeXYOffset[] = {0, 3072, 3072 + 1008, 3072 + 1008 + 3072};
    static constexpr size_t coordinatesOffset[] = {
        n_dimensions * 0,
        n_dimensions * 18432,
        n_dimensions * 18432 * 2,
        n_dimensions * 18432 * 3,
        n_dimensions * 18432 * 4,
        n_dimensions * (18432 * 4 + 4032),
        n_dimensions * (18432 * 4 + 4032 * 2),
        n_dimensions * (18432 * 4 + 4032 * 2 + 2016),
        n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2),
        n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536),
        n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536 * 2),
        n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536 * 2 + 1920),
        n_dimensions * (18432 * 4 + 4032 * 2 + 2016 * 2 + 1536 * 2 + 1920 * 2)
    };
    int gridX[Constants::n_stations * Constants::n_regions * n_tables];
    int gridY[Constants::n_stations * Constants::n_regions * n_tables];
    float sizeX[sizeXYOffset[n_tables]];
    float sizeY[sizeXYOffset[n_tables]];
    unsigned int offset[Constants::n_stations * Constants::n_regions * n_tables];
    unsigned int sizeOffset[Constants::n_stations * Constants::n_regions * n_tables];
    float coordinates[coordinatesOffset[n_tables * Constants::n_stations]];
  };

  __constant__ extern size_t tableStationRegionOffset[];
  __constant__ extern size_t sizeXYOffset[];
  __constant__ extern size_t coordinatesOffset[];

  __device__ inline unsigned int getLayoutX(MuonTables* muonTables, size_t tableNumber, unsigned int station,
      unsigned int region) {
    return static_cast<unsigned int>(muonTables->gridX[
        tableStationRegionOffset[tableNumber] +
        station * Constants::n_regions +
        region]
    );
  }

  __device__ inline unsigned int getLayoutY(MuonTables* muonTables, size_t tableNumber, unsigned int station,
      unsigned int region) {
    return static_cast<unsigned int>(muonTables->gridY[
        tableStationRegionOffset[tableNumber] +
        station * Constants::n_regions +
        region]
    );
  }

  void read_muon_tables(const char* raw_input, MuonTables* MuonTables);

  __device__ void calcPos(MuonTables* muonTables, size_t tableNumber, Muon::MuonTileID& tile, unsigned int offset_index, double& x,
               double& deltax, double& y, double& deltay, double& z);

  __device__ void calcTilePos(MuonTables* muonTables, Muon::MuonTileID& tile, double& x, double& deltax,
                   double& y, double& deltay, double& z);

  __device__ void calcStripXPos(MuonTables* muonTables, Muon::MuonTileID& tile, double& x, double& deltax,
                     double& y, double& deltay, double& z);

  __device__ void calcStripYPos(MuonTables* muonTables, Muon::MuonTileID& tile, double& x, double& deltax,
                     double& y, double& deltay, double& z);
};
