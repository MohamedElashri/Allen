/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "SystemOfUnits.h"

namespace Jets {
  static constexpr float pt_sum_precision = 0.1f * Allen::Units::MeV;
  static constexpr float eta_weighted_sum_precision = 0.1f * Allen::Units::MeV;
  static constexpr float phi_weighted_sum_precision = 0.01f * Allen::Units::MeV;

  struct Jet {
    // Jet kinematics.
    float pt = 0.f;
    float track_pt = 0.f;
    float corrected_pt = 0.f;
    float eta = 0.f;
    float phi = 0.f;
    // Jet constituents.
    unsigned n_tracks = 0;
    unsigned n_calos = 0;
  };
} // namespace Jets
