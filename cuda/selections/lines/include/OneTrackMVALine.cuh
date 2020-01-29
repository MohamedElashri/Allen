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

  struct OneTrackMVA_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"OneTrackMVA"};

    static __device__ bool function(const ParKalmanFilter::FittedTrack& track)
    {
      float ptShift = (track.pt() - alpha) / Gaudi::Units::GeV;
      bool decision = track.chi2 / track.ndof < maxChi2Ndof;
      decision &=
        ((ptShift > maxPt && track.ipChi2 > minIPChi2) ||
         (ptShift > minPt && ptShift < maxPt &&
          logf(track.ipChi2) >
            param1 / (ptShift - param2) / (ptShift - param2) + param3 / maxPt * (maxPt - ptShift) + logf(minIPChi2)));
      return decision;
    }
  };
} // namespace OneTrackMVA
