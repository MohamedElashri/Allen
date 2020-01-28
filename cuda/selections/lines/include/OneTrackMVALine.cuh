#pragma once

#include "LineInfo.cuh"
#include "ParKalmanDefinitions.cuh"
#include "SystemOfUnits.h"

namespace OneTrackMVA {
  // One track parameters.
  constexpr float maxChi2Ndof =
    10000.0f; // Large for now until we better understand the parameterized Kalman fit quality.
  constexpr float minPt = 1000.0f / Gaudi::Units::GeV;
  constexpr float maxPt = 25000.0f / Gaudi::Units::GeV;
  constexpr float minIPChi2 = 10.0f;
  constexpr float param1 = 1.0f;
  constexpr float param2 = 1.0f;
  constexpr float param3 = 1.1f;
  constexpr float alpha = 2500.0f;

  __device__ bool OneTrackMVA(const ParKalmanFilter::FittedTrack& track);

  struct OneTrackMVA_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"OneTrackMVA"};
    constexpr static auto function = &OneTrackMVA;
  };
} // namespace OneTrackMVA
