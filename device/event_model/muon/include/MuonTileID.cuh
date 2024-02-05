/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "MuonBase.cuh"
#include "MuonLayout.cuh"
#include "MuonDefinitions.cuh"
#include "LHCbID.cuh"

class MuonLayout;

namespace Muon {
  class MuonTileID {
  private:
    unsigned int m_muonid;

    __host__ __device__ void set(const unsigned int value, const unsigned int shift, const unsigned int mask)
    {
      unsigned int tmp1, tmp2;
      tmp1 = (value << shift) & mask;
      tmp2 = m_muonid & ~mask;
      m_muonid = (tmp1 | tmp2);
    }

  public:
    __host__ __device__ MuonTileID(unsigned int muonid) { m_muonid = muonid; }

    __host__ __device__ MuonTileID() { m_muonid = 0; }

    __host__ __device__ static unsigned int stationRegionQuarter(unsigned int id)
    {
      return MuonTileID::station(id) * Constants::n_stations * Constants::n_regions +
             MuonTileID::region(id) * Constants::n_regions + MuonTileID::quarter(id);
    }

    __host__ __device__ unsigned int stationRegionQuarter() const
    {
      return MuonTileID::station(m_muonid) * Constants::n_stations * Constants::n_regions +
             MuonTileID::region(m_muonid) * Constants::n_regions + MuonTileID::quarter(m_muonid);
    }

    __host__ __device__ static unsigned int station(unsigned int id)
    {
      return (id & MuonBase::MaskStation) >> MuonBase::ShiftStation;
    }

    __host__ __device__ unsigned int station() const
    {
      return (m_muonid & MuonBase::MaskStation) >> MuonBase::ShiftStation;
    }

    __host__ __device__ static unsigned int region(unsigned int id)
    {
      return (id & MuonBase::MaskRegion) >> MuonBase::ShiftRegion;
    }

    __host__ __device__ unsigned int region() const
    {
      return (m_muonid & MuonBase::MaskRegion) >> MuonBase::ShiftRegion;
    }

    __host__ __device__ static unsigned int quarter(unsigned int id)
    {
      return (id & MuonBase::MaskQuarter) >> MuonBase::ShiftQuarter;
    }

    __host__ __device__ unsigned int quarter() const
    {
      return (m_muonid & MuonBase::MaskQuarter) >> MuonBase::ShiftQuarter;
    }

    __host__ __device__ static MuonLayout layout(unsigned int id)
    {
      const unsigned int xg = (id & MuonBase::MaskLayoutX) >> MuonBase::ShiftLayoutX;
      const unsigned int yg = (id & MuonBase::MaskLayoutY) >> MuonBase::ShiftLayoutY;
      return {xg, yg};
    }

    __host__ __device__ MuonLayout layout() const
    {
      const unsigned int xg = (m_muonid & MuonBase::MaskLayoutX) >> MuonBase::ShiftLayoutX;
      const unsigned int yg = (m_muonid & MuonBase::MaskLayoutY) >> MuonBase::ShiftLayoutY;
      return {xg, yg};
    }

    __host__ __device__ static unsigned int nX(unsigned int id) { return (id & MuonBase::MaskX) >> MuonBase::ShiftX; }

    __host__ __device__ unsigned int nX() const { return (m_muonid & MuonBase::MaskX) >> MuonBase::ShiftX; }

    __host__ __device__ static unsigned int nY(unsigned int id) { return (id & MuonBase::MaskY) >> MuonBase::ShiftY; }

    __host__ __device__ unsigned int nY() const { return (m_muonid & MuonBase::MaskY) >> MuonBase::ShiftY; }

    __host__ __device__ void setX(const unsigned int x) { set(x, MuonBase::ShiftX, MuonBase::MaskX); }

    __host__ __device__ void setY(const unsigned int y) { set(y, MuonBase::ShiftY, MuonBase::MaskY); }

    __host__ __device__ void setLayout(MuonLayout layout)
    {
      const unsigned int lx = layout.xGrid();
      const unsigned int ly = layout.yGrid();
      set(lx, MuonBase::ShiftLayoutX, MuonBase::MaskLayoutX);
      set(ly, MuonBase::ShiftLayoutY, MuonBase::MaskLayoutY);
    }

    __host__ __device__ unsigned int id() const { return m_muonid; }

    __host__ __device__ unsigned int lhcbID() const
    {
      // Based on:
      // https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Kernel/LHCbKernel/include/Kernel/LHCbID.h
      MuonLayout lay = layout();
      unsigned int compact_layout = lay.xGrid() + lay.yGrid() * MuonBase::max_compacted_xGrid;
      unsigned int lhcb_id = ((static_cast<unsigned int>(lhcb_id::LHCbIDType::Muon) << lhcb_id::detectorTypeBits) &
                              lhcb_id::lhcbIDMasks::detectorTypeMask) |
                             ((compact_layout << MuonBase::ShiftCompactedLayout) & MuonBase::MaskCompactedLayout) |
                             (m_muonid & MuonBase::MaskKey);
      return lhcb_id;
    }
  };
} // namespace Muon
