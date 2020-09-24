/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "CudaCommon.h"
#include "MuonTileID.cuh"

namespace Muon {
  class MuonTileID;

  class MuonLayout {
  public:
    __device__ MuonLayout()
    {
      m_xgrid = 0;
      m_ygrid = 0;
    }

    __device__ MuonLayout(unsigned int xgrid, unsigned int ygrid)
    {
      m_xgrid = xgrid;
      m_ygrid = ygrid;
    }

    __device__ unsigned int xGrid() const { return m_xgrid; }

    __device__ unsigned int yGrid() const { return m_ygrid; }

  private:
    unsigned int m_xgrid;
    unsigned int m_ygrid;
  };

  __device__ inline bool operator==(const MuonLayout& ml1, const MuonLayout& ml2)
  {
    return ml1.xGrid() == ml2.xGrid() && ml1.yGrid() == ml2.yGrid();
  }

  __device__ inline bool operator!=(const MuonLayout& ml1, const MuonLayout& ml2) { return !(ml1 == ml2); }
} // namespace Muon
