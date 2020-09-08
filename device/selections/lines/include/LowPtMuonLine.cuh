/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LineInfo.cuh"
#include "ParKalmanDefinitions.cuh"
#include "SystemOfUnits.h"

namespace LowPtMuon {
  constexpr float minIP = 4.f;
  // NB: This pt cut is looser than default tracking threshold.
  constexpr float minPt = 80.f / Gaudi::Units::MeV;
  constexpr float maxChi2Ndof = 100.f;
  constexpr float minIPChi2 = 7.4;

  struct LowPtMuon_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"LowPtMuon"};

    static __device__ bool function(const ParKalmanFilter::FittedTrack& track) {
      if (!track.is_muon) return false;
      if (track.ip < minIP) return false;
      if (track.ipChi2 < minIPChi2) return false;
      if (track.pt() < minPt) return false;
      if (track.chi2 / track.ndof > maxChi2Ndof) return false;
      return true;
    }
  };

}