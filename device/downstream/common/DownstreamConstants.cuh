/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
\*****************************************************************************/
#pragma once

#include "UTEventModel.cuh"
// #include "SystemOfUnits.h"
// #include <cstdint>

namespace Downstream {

  namespace DownstreamParameters {
    // Max number of hit cached in shared memory
    constexpr unsigned MaxNumHitCachedSharedMemory = 1024;

    // Max number of downstream scifi seed
    constexpr unsigned MaxNumDownstreamSciFi = UT::Constants::max_num_tracks;

    // Max number of selected x3 hits per scifi seed
    constexpr unsigned MaxNumSelectedX3HitPerScifi = 10;

    // Max number of selected UV hits per each row
    constexpr unsigned MaxNumSelectedUVhitPerRow = 2;

    // Max number of row in search table
    constexpr unsigned MaxNumSelectedX3Hit = MaxNumSelectedX3HitPerScifi * MaxNumDownstreamSciFi;

    // Max number of cached sectors
    constexpr unsigned MaxNumCachedSector = 24;

    // Max number of UT sectors
    constexpr unsigned MaxNumSector = MaxNumCachedSector * UT::Constants::n_layers;

  } // namespace DownstreamParameters
} // namespace Downstream
