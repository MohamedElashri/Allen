/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"
#include "ParKalmanDefinitions.cuh"
#include "SystemOfUnits.h"

namespace TrackMVA {
  // One track parameters.
  constexpr float maxChi2Ndof =
    2.5f; // Large for now until we better understand the parameterized Kalman fit quality.
  constexpr float minPt = 2000.0f / Gaudi::Units::GeV;
  constexpr float maxPt = 26000.0f / Gaudi::Units::GeV;
  constexpr float minIPChi2 = 7.4f;
  constexpr float param1 = 1.0f;
  constexpr float param2 = 2.0f;
  constexpr float param3 = 1.248f;
  constexpr float alpha = 0.f;

  // (DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack), dev_kf_tracks),
  // const ParKalmanFilter::FittedTrack* event_tracks =
  //   parameters.dev_kf_tracks + parameters.dev_offsets_forward_tracks[selected_event_number];

  struct TrackMVA_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"TrackMVA"};

    static __device__ bool function(const ParKalmanFilter::FittedTrack& track)
    {
      float ptShift = (track.pt() - alpha) / Gaudi::Units::GeV;
      const bool decision = track.chi2 / track.ndof < maxChi2Ndof &&
                            ((ptShift > maxPt && track.ipChi2 > minIPChi2) ||
                             (ptShift > minPt && ptShift < maxPt &&
                              logf(track.ipChi2) > param1 / (ptShift - param2) / (ptShift - param2) +
                                                     param3 / maxPt * (maxPt - ptShift) + logf(minIPChi2)));
      return decision;
    }
  };
} // namespace TrackMVA
