#pragma once

#include "MuonTileID.h"

#include <vector>
#include <algorithm>

namespace Muon {
  class MuonGeometry {
  private:
    std::vector<std::vector<unsigned int>> m_tiles;

  public:
    void read_muon_geometry(const char *raw_input);

    unsigned int getADDInTell1(unsigned int Tell1_num, unsigned int ch) const;
  };
};
