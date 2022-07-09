/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <tuple>
#include "States.cuh"

namespace track_matching {

  struct Match {
    int ivelo;
    float chi2;
  };

  struct MatchingResult {
    float dSlopeX;
    float dSlopeY;
    float distX;
    float distY;
    float zForX;
    float chi2;
  };

}; // namespace track_matching