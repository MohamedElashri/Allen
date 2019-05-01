#include "MuonGeometry.cuh"

namespace Muon {
  constexpr size_t MuonGeometry::offset[];
  constexpr size_t MuonGeometry::sizes[];

  unsigned int MuonGeometry::getADDInTell1(unsigned int Tell1_num, unsigned int ch) const {
    if (Tell1_num <= m_tiles_size) {
      if (ch < sizes[Tell1_num]) {
        return m_tiles[offset[Tell1_num] + ch];
      }
    }
    return 0;
  }

  void MuonGeometry::read_muon_geometry(const char* raw_input) {
    for (int i = 0; i < 5; i++) {
      size_t size;
      std::copy_n((size_t*) raw_input, 1, &size);
      raw_input += sizeof(size_t);
      raw_input += sizeof(float) * size;
    }

    size_t nTilesSize;
    std::copy_n((size_t*) raw_input, 1, &nTilesSize);
    raw_input += sizeof(size_t);
    for (size_t i = 0; i < nTilesSize; i++) {
      size_t tilesSize;
      std::copy_n((size_t*) raw_input, 1, &tilesSize);
      raw_input += sizeof(size_t);
      std::copy_n((unsigned*) raw_input, tilesSize, m_tiles + offset[i]);
      raw_input += sizeof(unsigned) * tilesSize;
    }
  }
};
