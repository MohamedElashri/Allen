#pragma once

#include "LineInfo.cuh"
#include "ParKalmanDefinitions.cuh"
#include "SystemOfUnits.h"

namespace SingleMuon {
  constexpr float maxChi2Ndof = 10000.f;
  constexpr float singleMinPt = 10000.f / Gaudi::Units::MeV;

  struct SingleMuon_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"SingleMuon"};
    
    static __device__ bool function(const ParKalmanFilter::FittedTrack& track);
  };
} // namespace SingleMuon
