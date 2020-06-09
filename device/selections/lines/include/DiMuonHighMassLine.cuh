#pragma once

#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace DiMuonHighMass {
  // High mass dimuon (J/Psi).
  // NB: p and pt cuts are switched from Moore.
  constexpr float minHighMassTrackPt = 300.f / Gaudi::Units::MeV;
  constexpr float minHighMassTrackP = 6000.f / Gaudi::Units::MeV;
  constexpr float minMass = 2700.f / Gaudi::Units::MeV;
  constexpr float maxDoca = 0.2f;
  constexpr float maxVertexChi2 = 25.f;
  
  struct DiMuonHighMass_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"DiMuonHighMass"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      if (!vertex.is_dimuon) return false;
      if (vertex.doca > maxDoca) return false;
      if (vertex.mdimu < minMass) return false;
      if (vertex.minpt < minHighMassTrackPt) return false;
      if (vertex.p1 < minHighMassTrackP || vertex.p2 < minHighMassTrackP) return false;
      
      const bool decision = vertex.chi2 > 0 && vertex.chi2 < maxVertexChi2;
      return decision;
    }
  };
} // namespace DiMuonHighMass
