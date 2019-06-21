#include "MuonGeometry.h"

namespace CPUMuon {
  unsigned int MuonGeometry::getADDInTell1(unsigned int Tell1_num, unsigned int ch) const
  {
    MuonTileID emptyTile;
    if (Tell1_num <= m_tiles.size()) {
      if (ch < (m_tiles[Tell1_num]).size()) {
        return (m_tiles[Tell1_num])[ch];
      }
    }
    return 0;
  }

  void MuonGeometry::read_muon_geometry(const char* raw_input)
  {
    /**
     * 5 stands for innerX, innerY, outerX, outerY, stationZ arrays that
     * are dumped but are not used here so should be skipped during reading
     */
    for (int i = 0; i < 5; i++) {
      size_t size;
      std::copy_n((size_t*) raw_input, 1, &size);
      raw_input += sizeof(size_t);
      raw_input += sizeof(float) * size;
    }

    size_t nTilesSize;
    std::copy_n((size_t*) raw_input, 1, &nTilesSize);
    raw_input += sizeof(size_t);
    m_tiles.resize(nTilesSize);

    for (size_t i = 0; i < nTilesSize; i++) {
      size_t tilesSize;
      std::copy_n((size_t*) raw_input, 1, &tilesSize);
      raw_input += sizeof(size_t);
      std::vector<unsigned>& tiles = m_tiles[i];
      tiles.insert(tiles.end(), (unsigned*) raw_input, ((unsigned*) (raw_input)) + tilesSize);
      raw_input += sizeof(unsigned) * tilesSize;
    }
  }
}; // namespace CPUMuon
