/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SystemOfUnits.h"

#include <cstdint>

namespace TrackMatchingConsts {
  static constexpr unsigned max_num_tracks = 1000; // to do: what is the best / safest value here?

  constexpr float z_match = 5240.0f; // FIXME_GEOMETRY_HARDCODING
  constexpr float zMatchY = 10000.f; // in mm

  constexpr float dxTol = 10.12f;     // in mm
  constexpr float dxTolSlope = 101.f; // in mm

  constexpr float dyTol = 1.59f;       // in mm
  constexpr float dyTolSlope = 212.1f; // in mm
  constexpr float fastYTol = 250.f;    // to scan
  // The main cut values
  constexpr float maxChi2 = 2.f;
  constexpr float minNN = 0.25f; // not used so far

  // Magnetic parametrization from Velo + SciFi tracks
  struct MagnetParametrization {
    float zMagnetParamsMatch[5] {5287.6f, -7.98878f, 317.683f, 0.0119379f, -1418.42f};
    float bendYParams[2] {-347.801f, -42663.6f};
  };

  //// Magnetic parametrization from UT + SciFi tracks - KstMuMu sample
  // struct MagnetParametrization {
  //   float zMagnetParamsMatch[5] {5364.11f, -9.73763f, 281.102f, 0.0157596f, -1537.99f};
  //   float bendYParams[2] { -613.43f, -40937.7f};
  //};
  // Magnetic parametrization from UT + SciFi tracks - BsPhiPhi sample
  // struct MagnetParametrization {
  //   float zMagnetParamsMatch[5] {5365.01f, -13.0937f, 284.524f, 0.015503f, -1525.71f };
  //   float bendYParams[2] { -510.472, -56929.7};
  //};
} // namespace TrackMatchingConsts
