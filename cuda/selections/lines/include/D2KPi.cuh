#pragma once

#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"
#include "LineInfo.cuh"

// D -> K Pi
namespace D2KPi {

  constexpr float mPi = 139.571 / Gaudi::Units::MeV;
  constexpr float mK = 493.667 / Gaudi::Units::MeV;
  constexpr float mD = 1864.83 / Gaudi::Units::MeV;

  constexpr float minComboPt = 2000.0f / Gaudi::Units::MeV;
  constexpr float maxVertexChi2 = 10.f;
  constexpr float minEta = 2.0f;
  constexpr float maxEta = 5.0f;
  constexpr float minTrackPt = 200.f / Gaudi::Units::MeV;
  constexpr float minTrackIPChi2 = 9.f;
  constexpr float massWindow = 100.f / Gaudi::Units::MeV;

  struct D2KPi_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"D2KPi"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      if (vertex.chi2 < 0) {
        return false;
      }
      const float m1 = vertex.m(Masses::K, Masses::Pi);
      const float m2 = vertex.m(Masses::Pi, Masses::K);
      const bool decision =
        vertex.pt() > minComboPt &&
        vertex.chi2 < maxVertexChi2 &&
        vertex.eta > minEta &&
        vertex.eta < maxEta &&
        vertex.minpt > minTrackPt &&
        vertex.minipchi2 > minTrackIPChi2 &&
        std::min(fabsf(m1 - Masses::D), fabsf(m2 - Masses::D)) < massWindow;
      return decision;

    }
  }; 
} // namespace D2KPi



} // namespace D -> K K
