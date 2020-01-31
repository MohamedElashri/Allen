#pragma once

#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace DiMuonTrackEff {
  // Mass window around J/psi meson.
  constexpr float DMTrackEffM0 = 2000.f;
  constexpr float DMTrackEffM1 = 4000.f;

  struct DiMuonTrackEff_t : public Hlt1::VeloUTTwoTrackLine {
    constexpr static auto name {"DiMuonTrackEff"};

    static __device__ bool function(const VertexFit::TrackMVAVertex& vertex)
    {
      //if (!vertex.is_dimuon) return false;
      const bool decision = vertex.mdimu > DMTrackEffM0 && vertex.mdimu < DMTrackEffM1;
      return decision;
    }
  };
} // namespace DiMuonTrackEff