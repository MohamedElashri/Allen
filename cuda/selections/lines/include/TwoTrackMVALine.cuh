#pragma once

#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"
#include "LineInfo.cuh"

namespace TwoTrackMVA {
  // Two track parameters.
  constexpr float minComboPt = 2000.0f / Gaudi::Units::MeV;
  constexpr float maxVertexChi2 = 25.0f;
  constexpr float minMCor = 1000.0f / Gaudi::Units::MeV;
  constexpr float minEta = 2.0f;
  constexpr float maxEta = 5.0f;
  constexpr float minTrackPt = 700.f / Gaudi::Units::MeV;
  constexpr int maxNTrksAssoc = 1;  // Placeholder. To be replaced with MVA selection.
  constexpr float minFDChi2 = 0.0f; // Placeholder. To be replaced with MVA selection.
  constexpr float minTrackIPChi2 = 12.f;

  struct TwoTrackMVA_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"TwoTrackMVA"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex);
  };
} // namespace TwoTrackMVA