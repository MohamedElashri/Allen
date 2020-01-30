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

  struct DisplacedDiMuon_t : public Hlt1::TwoTrackLine {
    constexpr static auto name {"DisplacedDiMuon"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      if (!vertex.is_dimuon) return false;
      if (vertex.minipchi2 < dispMinIPChi2) return false;
      //TODO temporary hardcoded mass cut to reduce CPU-GPU differences
      if (vertex.mdimu < 215.f) return false;

      bool decision = vertex.chi2 > 0;
      decision &= vertex.chi2 < maxVertexChi2;
      decision &= vertex.eta > dispMinEta && vertex.eta < dispMaxEta;
      decision &= vertex.minpt > minDispTrackPt;
      return decision;
    }
  };
} // namespace DisplacedDiMuon
