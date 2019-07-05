#pragma once

#include <vector>
#include <array>
#include <algorithm>

#include "MuonTileID.h"
#include "MuonLayout.h"
#include "MuonDefinitions.cuh"

namespace CPUMuon {
  class MuonTable {
  public:
    std::vector<int> gridX, gridY;
    std::vector<float> sizeX, sizeY;
    std::vector<unsigned int> offset, sizeOffset;
    std::vector<std::vector<std::vector<float>>> points;
  };

  inline unsigned int getLayoutX(MuonTable* muonTable, unsigned int station, unsigned int region)
  {
    return muonTable->gridX[station * 4 + region];
  }

  inline unsigned int getLayoutY(MuonTable* muonTable, unsigned int station, unsigned int region)
  {
    return muonTable->gridY[station * 4 + region];
  }

  void read_muon_table(const char* raw_input, MuonTable* pad, MuonTable* stripX, MuonTable* stripY);

  void calcPos(
    MuonTable* muonTable,
    MuonTileID& tile,
    unsigned int offset_index,
    double& x,
    double& deltax,
    double& y,
    double& deltay,
    double& z);

  void calcTilePos(MuonTable* pad, MuonTileID& tile, double& x, double& deltax, double& y, double& deltay, double& z);

  void
  calcStripPos(MuonTable* strip, MuonTileID& tile, double& x, double& deltax, double& y, double& deltay, double& z);
}; // namespace CPUMuon
