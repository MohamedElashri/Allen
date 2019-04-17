#pragma once

#include "MuonTileID.h"

#include <vector>

namespace Muon {
  class MuonTileID;
}

class MuonLayout {
public:
  MuonLayout() {
    m_xgrid = 0;
    m_ygrid = 0;
  }

  MuonLayout(unsigned int xgrid, unsigned int ygrid) {
    m_xgrid = xgrid;
    m_ygrid = ygrid;
  }

  MuonLayout(std::pair<unsigned int, unsigned int> xygrid) {
    m_xgrid = xygrid.first;
    m_ygrid = xygrid.second;
  }

  unsigned int xGrid() const { return m_xgrid; }

  unsigned int yGrid() const { return m_ygrid; }

private:
  unsigned int m_xgrid;
  unsigned int m_ygrid;
};

inline bool operator==(const MuonLayout &ml1, const MuonLayout &ml2) {
  return ml1.xGrid() == ml2.xGrid() &&
         ml1.yGrid() == ml2.yGrid();
}

inline bool operator!=(const MuonLayout &ml1, const MuonLayout &ml2) {
  return !(ml1 == ml2);
}
