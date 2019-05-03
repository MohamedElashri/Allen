#pragma once

#include <string>

#include "MuonBase.cuh"
#include "MuonLayout.h"

namespace CPUMuon {
  class MuonLayout;

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
      return (id & ::Muon::MuonBase::MaskStation) >> ::Muon::MuonBase::ShiftStation;
    }

    unsigned int station() const {
      return (m_muonid & ::Muon::MuonBase::MaskStation) >> ::Muon::MuonBase::ShiftStation;
    }

    unsigned int region() const {
      return (m_muonid & ::Muon::MuonBase::MaskRegion) >> ::Muon::MuonBase::ShiftRegion;
    }

    unsigned int quarter() const {
      return (m_muonid & ::Muon::MuonBase::MaskQuarter) >> ::Muon::MuonBase::ShiftQuarter;
    }

    MuonLayout layout() const {
      unsigned int xg = (m_muonid & ::Muon::MuonBase::MaskLayoutX) >> ::Muon::MuonBase::ShiftLayoutX;
      unsigned int yg = (m_muonid & ::Muon::MuonBase::MaskLayoutY) >> ::Muon::MuonBase::ShiftLayoutY;
      return {xg, yg};
    }

    unsigned int nX() const {
      return (m_muonid & ::Muon::MuonBase::MaskX) >> ::Muon::MuonBase::ShiftX;
    }

    unsigned int nY() const {
      return (m_muonid & ::Muon::MuonBase::MaskY) >> ::Muon::MuonBase::ShiftY;
    }

    void setX(const unsigned int x) {
      set(x, ::Muon::MuonBase::ShiftX, ::Muon::MuonBase::MaskX);
    }

    void setY(const unsigned int y) {
      set(y, ::Muon::MuonBase::ShiftY, ::Muon::MuonBase::MaskY);
    }

    void setLayout(MuonLayout layout) {
      unsigned int lx, ly;
      lx = layout.xGrid();
      ly = layout.yGrid();
      set(lx, ::Muon::MuonBase::ShiftLayoutX, ::Muon::MuonBase::MaskLayoutX);
      set(ly, ::Muon::MuonBase::ShiftLayoutY, ::Muon::MuonBase::MaskLayoutY);
    }

    unsigned int id() const {
      return m_muonid;
    }
  };
};
