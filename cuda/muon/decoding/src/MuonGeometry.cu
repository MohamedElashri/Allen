#include "MuonGeometry.cuh"

namespace Muon {
  __device__ unsigned int MuonGeometry::getADDInTell1(unsigned int Tell1_num, unsigned int ch) const
  {
    if (Tell1_num <= m_tiles_size) {
      if (ch < m_sizes[Tell1_num]) {
        return m_tiles[Tell1_num][ch];
      }
    }
    return 0;
  }
} // namespace Muon
