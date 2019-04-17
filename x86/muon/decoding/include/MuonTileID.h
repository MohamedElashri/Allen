#pragma once

#include "MuonBase.h"
#include "MuonLayout.h"

#include <string>

class MuonLayout;

namespace Muon {
  class MuonTileID {
  private:
    unsigned int m_muonid;

    void set(const unsigned int value, const unsigned int shift, const unsigned int mask) {
      unsigned int tmp1, tmp2;
      tmp1 = (value << shift) & mask;
      tmp2 = m_muonid & ~mask;
      m_muonid = (tmp1 | tmp2);
    }

  public:
    MuonTileID(unsigned int muonid) {
      m_muonid = muonid;
    }

    MuonTileID() {
      m_muonid = 0;
    }

    static unsigned int station(unsigned int id) {
      return (id & MuonBase::MaskStation) >> MuonBase::ShiftStation;
    }

    unsigned int station() const {
      return (m_muonid & MuonBase::MaskStation) >> MuonBase::ShiftStation;
    }

    unsigned int region() const {
      return (m_muonid & MuonBase::MaskRegion) >> MuonBase::ShiftRegion;
    }

    unsigned int quarter() const {
      return (m_muonid & MuonBase::MaskQuarter) >> MuonBase::ShiftQuarter;
    }

    MuonLayout layout() const {
      unsigned int xg = (m_muonid & MuonBase::MaskLayoutX) >> MuonBase::ShiftLayoutX;
      unsigned int yg = (m_muonid & MuonBase::MaskLayoutY) >> MuonBase::ShiftLayoutY;
      return {xg, yg};
    }

    unsigned int nX() const {
      return (m_muonid & MuonBase::MaskX) >> MuonBase::ShiftX;
    }

    unsigned int nY() const {
      return (m_muonid & MuonBase::MaskY) >> MuonBase::ShiftY;
    }

    void setX(const unsigned int x) {
      set(x, MuonBase::ShiftX, MuonBase::MaskX);
    }

    void setY(const unsigned int y) {
      set(y, MuonBase::ShiftY, MuonBase::MaskY);
    }

    void setLayout(MuonLayout layout) {
      unsigned int lx, ly;
      lx = layout.xGrid();
      ly = layout.yGrid();
      set(lx, MuonBase::ShiftLayoutX, MuonBase::MaskLayoutX);
      set(ly, MuonBase::ShiftLayoutY, MuonBase::MaskLayoutY);
    }

    unsigned int id() const {
      return m_muonid;
    }
  };
};
