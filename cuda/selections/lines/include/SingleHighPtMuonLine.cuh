#pragma once

#include "LineInfo.cuh"
#include "ParKalmanDefinitions.cuh"
#include "SystemOfUnits.h"

namespace SingleHighPtMuon {
  constexpr float maxChi2Ndof = 100.f;
  constexpr float singleMinPt = 6000.f / Gaudi::Units::MeV;
  constexpr float singleMinP = 6000.f / Gaudi::Units::MeV;
  
  struct SingleHighPtMuon_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"SingleHighPtMuon"};

    static __device__ bool function(const ParKalmanFilter::FittedTrack& track)
    {
      const bool decision = track.chi2 / track.ndof < maxChi2Ndof &&
        track.pt() > singleMinPt && track.p() > singleMinP && track.is_muon;
      return decision;
    }
  };
} // namespace SingleMuon
