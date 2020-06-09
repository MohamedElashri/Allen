#pragma once

#include <algorithm>

#include "MuonTileID.cuh"

namespace Muon {
  class MuonGeometry {
  public:
    static constexpr size_t m_tiles_size = 10;
    unsigned* m_tiles[m_tiles_size];
    size_t m_sizes[m_tiles_size];

    MuonGeometry(size_t* sizes, unsigned** tiles)
    {
      for (size_t i = 0; i < m_tiles_size; i++) {
        m_sizes[i] = sizes[i];
        m_tiles[i] = tiles[i];
      }
    }

    MuonGeometry() {}

    __device__ inline unsigned int getADDInTell1(unsigned int Tell1_num, unsigned int ch) const
    {
      assert(Tell1_num <= m_tiles_size);
      assert(ch < m_sizes[Tell1_num]);
      
      return m_tiles[Tell1_num][ch];
    }
  };
} // namespace Muon
