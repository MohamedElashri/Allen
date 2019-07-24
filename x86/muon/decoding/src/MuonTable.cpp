#include "MuonTable.h"

namespace CPUMuon {
  size_t lookup_index(MuonTable* table, const MuonTileID& tile, unsigned int index)
  {
    int station = tile.station();
    int region = tile.region();
    int idx = 4 * station + region;
    int xpad = static_cast<int>(tile.nX());
    int ypad = static_cast<int>(tile.nY());

    if (ypad < table->gridY[idx]) {
      index = index + table->gridX[idx] * ypad + xpad - table->gridX[idx];
    }
    else {
      index = index + table->gridX[idx] * table->gridY[idx] + 2 * table->gridX[idx] * (ypad - table->gridY[idx]) + xpad;
    }
    return index;
  }

  size_t size_index(
    const std::vector<unsigned int>& offset,
    const std::vector<int>& gridX,
    const std::vector<int>& gridY,
    const MuonTileID& tile)
  {
    auto idx = 4 * tile.station() + tile.region();
    auto index = offset[idx] + tile.quarter() * gridY[idx] * 6;
    if (tile.nY() < static_cast<unsigned int>(gridY[idx])) {
      return index + 2 * tile.nY() + 2 * (tile.nX() - gridX[idx]) / gridX[idx];
    }
    else {
      return index + 4 * tile.nY() - 2 * gridY[idx] + (2 * tile.nX() / gridX[idx]);
    }
  }

  unsigned int pad_offset(MuonTable* pad, const MuonTileID& tile)
  {
    int idx = 4 * tile.station() + tile.region();
    int perQuarter = 3 * pad->gridX[idx] * pad->gridY[idx];
    return (4 * tile.region() + tile.quarter()) * perQuarter;
  }

  unsigned int strip_offset(MuonTable* strip, const MuonTileID& tile)
  {
    int idx = 4 * tile.station() + tile.region();
    int perQuarter = 3 * strip->gridX[idx] * strip->gridY[idx];
    return strip->offset[4 * tile.station() + tile.region()] + tile.quarter() * perQuarter;
  }

  void calcPos(
    MuonTable* muonTable,
    MuonTileID& tile,
    unsigned int offset_index,
    double& x,
    double& deltax,
    double& y,
    double& deltay,
    double& z)
  {
    int station = tile.station();
    auto index = lookup_index(muonTable, tile, offset_index);
    auto& p = muonTable->points[station][index];
    x = p[0];
    y = p[1];
    z = p[2];

    auto dxi = size_index(muonTable->sizeOffset, muonTable->gridX, muonTable->gridY, tile);
    deltax = muonTable->sizeX[dxi];
    deltay = muonTable->sizeY[dxi];
  }

  void calcTilePos(MuonTable* pad, MuonTileID& tile, double& x, double& deltax, double& y, double& deltay, double& z)
  {
    calcPos(pad, tile, pad_offset(pad, tile), x, deltax, y, deltay, z);
  }

  void calcStripPos(MuonTable* strip, MuonTileID& tile, double& x, double& deltax, double& y, double& deltay, double& z)
  {
    calcPos(strip, tile, strip_offset(strip, tile), x, deltax, y, deltay, z);
  }

  void read_muon_table(const char* raw_input, MuonTable* pad, MuonTable* stripX, MuonTable* stripY)
  {
    MuonTable* muonTables[3] = {pad, stripX, stripY};
    for (MuonTable* muonTable : muonTables) {
      size_t gridXSize;
      std::copy_n((size_t*) raw_input, 1, &gridXSize);
      raw_input += sizeof(size_t);
      (muonTable->gridX).insert((muonTable->gridX).end(), (int*) raw_input, ((int*) raw_input) + gridXSize);
      raw_input += sizeof(int) * gridXSize;

      size_t gridYSize;
      std::copy_n((size_t*) raw_input, 1, &gridYSize);
      raw_input += sizeof(size_t);
      (muonTable->gridY).insert((muonTable->gridY).end(), (int*) raw_input, ((int*) raw_input) + gridYSize);
      raw_input += sizeof(int) * gridYSize;

      size_t sizeXSize;
      std::copy_n((size_t*) raw_input, 1, &sizeXSize);
      raw_input += sizeof(size_t);
      (muonTable->sizeX).insert((muonTable->sizeX).end(), (float*) raw_input, ((float*) raw_input) + sizeXSize);
      raw_input += sizeof(float) * sizeXSize;

      size_t sizeYSize;
      std::copy_n((size_t*) raw_input, 1, &sizeYSize);
      raw_input += sizeof(size_t);
      (muonTable->sizeY).insert((muonTable->sizeY).end(), (float*) raw_input, ((float*) raw_input) + sizeYSize);
      raw_input += sizeof(float) * sizeYSize;

      size_t offsetSize;
      std::copy_n((size_t*) raw_input, 1, &offsetSize);
      raw_input += sizeof(size_t);
      (muonTable->offset)
        .insert((muonTable->offset).end(), (unsigned int*) raw_input, ((unsigned int*) raw_input) + offsetSize);
      raw_input += sizeof(unsigned int) * offsetSize;

      (muonTable->sizeOffset).resize((muonTable->gridY).size());
      muonTable->offset[0] = 0;
      for (size_t i = 0; i < muonTable->gridY.size() - 1; ++i) {
        muonTable->sizeOffset[i + 1] = muonTable->sizeOffset[i] + 24 * muonTable->gridY[i];
      }

      size_t tableSize;
      std::copy_n((size_t*) raw_input, 1, &tableSize);
      (muonTable->points).resize(tableSize);
      raw_input += sizeof(size_t);
      for (int i = 0; i < tableSize; i++) {
        size_t stationTableSize;
        std::copy_n((size_t*) raw_input, 1, &stationTableSize);
        raw_input += sizeof(size_t);
        (muonTable->points)[i].resize(stationTableSize);
        for (int j = 0; j < stationTableSize; j++) {
          (muonTable->points)[i][j].insert(
            (muonTable->points)[i][j].end(), (float*) raw_input, ((float*) raw_input) + 3);
          raw_input += sizeof(float) * 3;
        }
      }
    }
  }
}; // namespace CPUMuon
