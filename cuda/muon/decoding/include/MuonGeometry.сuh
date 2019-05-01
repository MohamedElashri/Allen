#pragma once

#include "MuonTileID.h"

namespace Muon {
  class MuonGeometry {
  public:
    static constexpr size_t m_tiles_size = 10;
    static constexpr size_t offset[] = {
        0,
        1536,
        1536 * 2,
        1536 * 3,
        1536 * 4,
        1536 * 4 + 3072,
        1536 * 4 + 3072 * 2,
        1536 * 4 + 3072 * 2 + 1920,
        1536 * 4 + 3072 * 2 + 1920 * 2,
        1536 * 4 + 3072 * 2 + 1920 * 3,
        1536 * 4 + 3072 * 2 + 1920 * 4
    };
    static constexpr size_t sizes[] = {
        1536,
        1536,
        1536,
        1536,
        3072,
        3072,
        1920,
        1920,
        1920,
        1920
    };

    void read_muon_geometry(const char* raw_input);

    unsigned int getADDInTell1(unsigned int Tell1_num, unsigned int ch) const;
  private:
    unsigned int m_tiles[offset[m_tiles_size]];
  };
};
