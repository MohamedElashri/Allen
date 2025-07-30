/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "SciFiDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
// #include "SystemOfUnits.h"
// #include <cstdint>

namespace Downstream {

  namespace DownstreamParameters {
    // Max number of downstream scifi seed
    constexpr unsigned MaxNumDownstreamSciFi = 400;

    // Max number of selected x3 hits per scifi seed
    constexpr unsigned MaxNumSelectedX3HitPerScifi = 10;

    // Max number of selected UV hits per each row
    constexpr unsigned MaxNumSelectedUVhitPerRow = 2;

    // Max number of downstream candidates
    constexpr unsigned MaxNumCandidates = 1024 * 4;

  } // namespace DownstreamParameters
} // namespace Downstream
