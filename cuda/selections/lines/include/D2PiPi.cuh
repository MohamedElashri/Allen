#pragma once

#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"
#include "LineInfo.cuh"

// D -> Pi Pi
namespace D2PiPi {

  constexpr float mPi = 139.571 / Gaudi::Units::MeV;
  constexpr float mD = 1864.83 / Gaudi::Units::MeV;

  constexpr float minComboPt = 2000.0f / Gaudi::Units::MeV;
  constexpr float maxVertexChi2 = 10.f;
  constexpr float minEta = 2.0f;
  constexpr float maxEta = 5.0f;
  constexpr float minTrackPt = 200.f / Gaudi::Units::MeV;
  constexpr float minTrackIPChi2 = 9.f;
  constexpr float massWindow = 100.f / Gaudi::Units::MeV;

  struct D2PiPi_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"D2PiPi"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      if (vertex.chi2 < 0) {
        return false;
      }
      const bool decision = vertex.pt() > minComboPt && vertex.chi2 < maxVertexChi2 && vertex.eta > minEta &&
                            vertex.eta < maxEta && vertex.minpt > minTrackPt && vertex.minipchi2 > minTrackIPChi2 &&
                            fabsf(vertex.m(mPi, mPi) - mD) < massWindow;
      return decision;
    }
  };
} // namespace D2PiPi
