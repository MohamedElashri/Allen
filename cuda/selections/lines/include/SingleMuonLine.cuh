#pragma once

#include "LineInfo.cuh"
#include "ParKalmanDefinitions.cuh"
#include "SystemOfUnits.h"

namespace SingleMuon {
  constexpr float maxChi2Ndof = 10000.f;
  constexpr float singleMinPt = 10000.f / Gaudi::Units::MeV;

  __device__ bool SingleMuon(const ParKalmanFilter::FittedTrack& track);

  struct SingleMuon_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"SingleMuon"};
    constexpr static auto function = &SingleMuon;
  };
} // namespace SingleMuon
