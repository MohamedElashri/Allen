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
    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex);
  };
} // namespace HighMassDiMuon
