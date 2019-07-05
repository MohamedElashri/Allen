#pragma once

#include "MuonBase.cuh"
#include "MuonLayout.cuh"
#include "MuonDefinitions.cuh"

class MuonLayout;

namespace Muon {
  class MuonTileID {
  private:
    unsigned int m_muonid;

    __device__ void set(const unsigned int value, const unsigned int shift, const unsigned int mask)
    {
      unsigned int tmp1, tmp2;
      tmp1 = (value << shift) & mask;
      tmp2 = m_muonid & ~mask;
      m_muonid = (tmp1 | tmp2);
    }

  public:
    __device__ MuonTileID(unsigned int muonid) { m_muonid = muonid; }

    __device__ MuonTileID() { m_muonid = 0; }

    __device__ static unsigned int stationRegionQuarter(unsigned int id)
    {
      return MuonTileID::station(id) * Constants::n_stations * Constants::n_regions +
             MuonTileID::region(id) * Constants::n_regions + MuonTileID::quarter(id);
    }

    __device__ static unsigned int station(unsigned int id)
    {
      return (id & MuonBase::MaskStation) >> MuonBase::ShiftStation;
    }

    __device__ unsigned int station() const { return (m_muonid & MuonBase::MaskStation) >> MuonBase::ShiftStation; }

    __device__ static unsigned int region(unsigned int id)
    {
      return (id & MuonBase::MaskRegion) >> MuonBase::ShiftRegion;
    }

    __device__ unsigned int region() const { return (m_muonid & MuonBase::MaskRegion) >> MuonBase::ShiftRegion; }

    __device__ static unsigned int quarter(unsigned int id)
    {
      return (id & MuonBase::MaskQuarter) >> MuonBase::ShiftQuarter;
    }

    __device__ unsigned int quarter() const { return (m_muonid & MuonBase::MaskQuarter) >> MuonBase::ShiftQuarter; }

    __device__ static MuonLayout layout(unsigned int id)
    {
      const unsigned int xg = (id & MuonBase::MaskLayoutX) >> MuonBase::ShiftLayoutX;
      const unsigned int yg = (id & MuonBase::MaskLayoutY) >> MuonBase::ShiftLayoutY;
      return {xg, yg};
    }

    __device__ MuonLayout layout() const
    {
      const unsigned int xg = (m_muonid & MuonBase::MaskLayoutX) >> MuonBase::ShiftLayoutX;
      const unsigned int yg = (m_muonid & MuonBase::MaskLayoutY) >> MuonBase::ShiftLayoutY;
      return {xg, yg};
    }

    __device__ static unsigned int nX(unsigned int id) { return (id & MuonBase::MaskX) >> MuonBase::ShiftX; }

    __device__ unsigned int nX() const { return (m_muonid & MuonBase::MaskX) >> MuonBase::ShiftX; }

    __device__ static unsigned int nY(unsigned int id) { return (id & MuonBase::MaskY) >> MuonBase::ShiftY; }

    __device__ unsigned int nY() const { return (m_muonid & MuonBase::MaskY) >> MuonBase::ShiftY; }

    __device__ void setX(const unsigned int x) { set(x, MuonBase::ShiftX, MuonBase::MaskX); }

    __device__ void setY(const unsigned int y) { set(y, MuonBase::ShiftY, MuonBase::MaskY); }

    __device__ void setLayout(MuonLayout layout)
    {
      const unsigned int lx = layout.xGrid();
      const unsigned int ly = layout.yGrid();
      set(lx, MuonBase::ShiftLayoutX, MuonBase::MaskLayoutX);
      set(ly, MuonBase::ShiftLayoutY, MuonBase::MaskLayoutY);
    }

    __device__ unsigned int id() const { return m_muonid; }
  };
} // namespace Muon
