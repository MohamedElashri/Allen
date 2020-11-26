#pragma once

namespace Calo {
  namespace Constants {
    constexpr uint16_t card_channels = 32;
    constexpr uint16_t ecal_max_index = 6016;
    constexpr uint16_t hcal_max_index = 1488;

    // Max distance based on CellIDs is 64 steps away, so the iteration in which a cell is clustered can never be more than 64.
    constexpr uint16_t unclustered = 65;
    constexpr uint16_t ignore = unclustered + 1;

    constexpr uint16_t digit_max_clusters = 15;
    constexpr uint16_t max_neighbours = 9;
  }
}
