#pragma once

#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace DisplacedDiMuon {
  // Dimuon track pt.
  constexpr float minDispTrackPt = 500.f / Gaudi::Units::MeV;
  constexpr float maxVertexChi2 = 6.f;

  // Displaced dimuon selections.
  constexpr float dispMinIPChi2 = 6.f;
  constexpr float dispMinEta = 2.f;
  constexpr float dispMaxEta = 5.f;

  __device__ bool DisplacedDiMuon(const VertexFit::TrackMVAVertex& vertex);

  struct DisplacedDiMuon_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"DisplacedDiMuon"};
    constexpr static auto function = &DisplacedDiMuon;
  };
} // namespace DisplacedDiMuon
