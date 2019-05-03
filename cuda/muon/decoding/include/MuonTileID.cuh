#pragma once

#include "MuonBase.cuh"
#include "MuonLayout.cuh"

class MuonLayout;

namespace Muon {
  class MuonTileID {
  private:
    unsigned int m_muonid;

    __host__ __device__ void set(const unsigned int value, const unsigned int shift, const unsigned int mask) {
      unsigned int tmp1, tmp2;
      tmp1 = (value << shift) & mask;
      tmp2 = m_muonid & ~mask;
      m_muonid = (tmp1 | tmp2);
    }

  public:
    __host__ __device__ MuonTileID(unsigned int muonid) {
      m_muonid = muonid;
    }

    __host__ __device__ MuonTileID() {
      m_muonid = 0;
    }

    __host__ __device__ static unsigned int station(unsigned int id) {
      return (id & MuonBase::MaskStation) >> MuonBase::ShiftStation;
    }

    __host__ __device__ unsigned int station() const {
      return (m_muonid & MuonBase::MaskStation) >> MuonBase::ShiftStation;
    }

    __host__ __device__ unsigned int region() const {
      return (m_muonid & MuonBase::MaskRegion) >> MuonBase::ShiftRegion;
    }

    __host__ __device__ unsigned int quarter() const {
      return (m_muonid & MuonBase::MaskQuarter) >> MuonBase::ShiftQuarter;
    }

    __host__ __device__ MuonLayout layout() const {
      unsigned int xg = (m_muonid & MuonBase::MaskLayoutX) >> MuonBase::ShiftLayoutX;
      unsigned int yg = (m_muonid & MuonBase::MaskLayoutY) >> MuonBase::ShiftLayoutY;
      return {xg, yg};
    }

    __host__ __device__ unsigned int nX() const {
      return (m_muonid & MuonBase::MaskX) >> MuonBase::ShiftX;
    }

    __host__ __device__ unsigned int nY() const {
      return (m_muonid & MuonBase::MaskY) >> MuonBase::ShiftY;
    }

    __host__ __device__ void setX(const unsigned int x) {
      set(x, MuonBase::ShiftX, MuonBase::MaskX);
    }

    __host__ __device__ void setY(const unsigned int y) {
      set(y, MuonBase::ShiftY, MuonBase::MaskY);
    }

    __host__ __device__ void setLayout(MuonLayout layout) {
      unsigned int lx, ly;
      lx = layout.xGrid();
      ly = layout.yGrid();
      set(lx, MuonBase::ShiftLayoutX, MuonBase::MaskLayoutX);
      set(ly, MuonBase::ShiftLayoutY, MuonBase::MaskLayoutY);
    }

    __host__ __device__ unsigned int id() const {
      return m_muonid;
    }
  };
};
