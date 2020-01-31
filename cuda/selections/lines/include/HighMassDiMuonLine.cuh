#pragma once

#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace HighMassDiMuon {
  // High mass dimuon (J/Psi).
  constexpr float minHighMassTrackPt = 750.f / Gaudi::Units::MeV;
  constexpr float minMass = 2700.f / Gaudi::Units::MeV;
  constexpr float maxVertexChi2 = 6.f;

  struct HighMassDiMuon_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"HighMassDiMuon"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      if (!vertex.is_dimuon) return false;
      if (vertex.mdimu < minMass) return false;
      if (vertex.minpt < minHighMassTrackPt) return false;

      const bool decision = vertex.chi2 > 0 && vertex.chi2 < maxVertexChi2;
      return decision;
    }
  };
} // namespace HighMassDiMuon
