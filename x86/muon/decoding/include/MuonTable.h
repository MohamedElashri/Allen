#pragma once

#include "MuonTileID.h"
#include "MuonLayout.h"
#include "MuonDefinitions.cuh"

#include <vector>
#include <array>
#include <algorithm>

class MuonTable {
public:
  std::vector<int> gridX, gridY;
  std::vector<float> sizeX, sizeY;
  std::vector<unsigned int> offset, sizeOffset;
  std::vector<std::vector<std::vector<float>>>points;
};

inline unsigned int getLayoutX(MuonTable*muonTable, unsigned int station, unsigned int region) {
  return muonTable->gridX[station * 4 + region];
}

inline unsigned int getLayoutY(MuonTable*muonTable, unsigned int station, unsigned int region) {
  return muonTable->gridY[station * 4 + region];
}

void read_muon_table(const char*raw_input, MuonTable*pad, MuonTable*stripX, MuonTable*stripY);

void calcPos(MuonTable*muonTable, Muon::MuonTileID& tile, unsigned int offset_index, double& x, double& deltax,
             double& y, double& deltay, double& z);

void calcTilePos(MuonTable*pad, Muon::MuonTileID& tile, double& x, double& deltax,
                 double& y, double& deltay, double& z);

void calcStripPos(MuonTable*strip, Muon::MuonTileID& tile, double& x, double& deltax,
                  double& y, double& deltay, double& z);

int transform_for_uncrossed_hits(Muon::MuonTileID& tile, MuonTable*pad, MuonTable*stripX, MuonTable*stripY,
                                 double& x, double& dx, double& y, double& dy, double& z);

