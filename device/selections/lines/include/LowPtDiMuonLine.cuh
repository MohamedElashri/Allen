/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace LowPtDiMuon {

  constexpr float minTrackIP = 0.1f;
  constexpr float minTrackPt = 80.f;
  constexpr float minTrackP = 3000.f;
  constexpr float minTrackIPChi2 = 1.f;
  constexpr float maxDOCA = 0.2f;
  constexpr float maxVertexChi2 = 25.f;
  constexpr float minMass = 220.f;

  struct LowPtDiMuon_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"LowPtDiMuon"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      if (!vertex.is_dimuon) return false;
      if (vertex.minipchi2 < minTrackIPChi2) return false;
      if (vertex.minip < minTrackIP) return false;
      
      const bool decision = vertex.chi2 > 0 && vertex.mdimu > minMass &&
        vertex.minpt > minTrackPt && vertex.p1 > minTrackP && vertex.p2 > minTrackP &&
        vertex.chi2 < maxVertexChi2 && vertex.doca < maxDOCA;
      return decision;
    }
  };
  
}