#pragma once

#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace DiMuonSoft {
  // Dimuon Soft  (Very Detached)
  constexpr float DMSoftM0 = 400.f;
  constexpr float DMSoftM1 = 475.f;
  constexpr float DMSoftMinIPChi2 = 100.f;
  constexpr float DMSoftMinRho2 = 9.f;
  constexpr float DMSoftMinZ = -375.f;
  constexpr float DMSoftMaxZ = 635.f;
  constexpr float DMSoftMaxDOCA = 0.2f;
  constexpr float DMSoftMaxIPDZ = 0.17f;
  constexpr float DMSoftGhost = 4.e-06f;

  struct DiMuonSoft_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"DiMuonSoft"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex);
  };
} // namespace DiMuonSoft
