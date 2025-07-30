/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once
#include <cstdint>

namespace Calo {
  namespace Constants {
    constexpr uint16_t card_channels = 32;
    constexpr uint16_t ecal_max_index = 6016;

    // Max distance based on CellIDs is 64 steps away, so the iteration in which a cell is clustered can never be more
    // than 64.
    constexpr uint16_t unclustered = 65;
    constexpr uint16_t ignore = unclustered + 1;

    constexpr uint16_t digit_max_clusters = 15;
    constexpr uint16_t max_neighbours = 9;

    constexpr uint16_t z = 12650;

    // Parameters to get region size out of region_s = region_size_0 + region_size_1 * region_index + region_size_2 *
    // region_index**2
    constexpr float region_size_0 = 121.2f;
    constexpr float region_size_1 = -80.8f;
    constexpr float region_size_2 = 20.2f;

    constexpr uint16_t n_electron_id_features = 6;
  } // namespace Constants
} // namespace Calo
