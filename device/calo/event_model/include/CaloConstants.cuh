
namespace Calo {
  namespace Constants {
    constexpr uint16_t card_channels = 32;
    constexpr uint16_t ecal_max_cellid = 0b11000000000000;
    constexpr uint16_t hcal_max_cellid = 0b10000000000000;
    constexpr uint16_t ecal_max_cells = 6015;
    constexpr uint16_t hcal_max_cells = 6015;

    // Max distance based on CellIDs is 64 steps away, so the iteration in which a cell is clustered can never be more than 64.
    constexpr uint16_t unclustered = 65;

    constexpr uint16_t digit_max_clusters = 15;
    constexpr uint16_t max_neighbours = 9;
  }
}
