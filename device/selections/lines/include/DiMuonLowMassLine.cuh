#pragma once

#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace DiMuonLowMass {
  constexpr float minHighMassTrackPt = 500.f / Gaudi::Units::MeV;
  constexpr float minHighMassTrackP = 3000.f / Gaudi::Units::MeV;
  constexpr float minMass = 0.f / Gaudi::Units::MeV;
  constexpr float maxDoca = 0.2f;
  constexpr float maxVertexChi2 = 25.f;
  constexpr float minIPChi2 = 4.f;
  
  struct DiMuonLowMass_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"DiMuonLowMass"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      if (!vertex.is_dimuon) return false;
      if (vertex.minipchi2 < minIPChi2) return false;
      if (vertex.doca > maxDoca) return false;
      if (vertex.mdimu < minMass) return false;
      if (vertex.minpt < minHighMassTrackPt) return false;
      if (vertex.p1 < minHighMassTrackP || vertex.p2 < minHighMassTrackP) return false;
      
      const bool decision = vertex.chi2 > 0 && vertex.chi2 < maxVertexChi2;
      return decision;
    }
  };
} // namespace DiMuonLowMass
