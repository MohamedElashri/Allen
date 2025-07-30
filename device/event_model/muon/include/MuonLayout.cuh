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

#include "BackendCommon.h"

namespace Muon {
  class MuonTileID;

  class MuonLayout {
  public:
    __host__ __device__ MuonLayout()
    {
      m_xgrid = 0;
      m_ygrid = 0;
    }

    __host__ __device__ MuonLayout(unsigned int xgrid, unsigned int ygrid)
    {
      m_xgrid = xgrid;
      m_ygrid = ygrid;
    }

    __host__ __device__ unsigned int xGrid() const { return m_xgrid; }

    __host__ __device__ unsigned int yGrid() const { return m_ygrid; }

  private:
    unsigned int m_xgrid;
    unsigned int m_ygrid;
  };

  __host__ __device__ inline bool operator==(const MuonLayout& ml1, const MuonLayout& ml2)
  {
    return ml1.xGrid() == ml2.xGrid() && ml1.yGrid() == ml2.yGrid();
  }

  __host__ __device__ inline bool operator!=(const MuonLayout& ml1, const MuonLayout& ml2) { return !(ml1 == ml2); }
} // namespace Muon
