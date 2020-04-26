#include "MuonGeometry.cuh"

namespace Muon {
  __device__ unsigned int MuonGeometry::getADDInTell1(unsigned int Tell1_num, unsigned int ch) const
  {
    assert(Tell1_num <= m_tiles_size);
    assert(ch < m_sizes[Tell1_num]);
    
    return m_tiles[Tell1_num][ch];
  }
} // namespace Muon
