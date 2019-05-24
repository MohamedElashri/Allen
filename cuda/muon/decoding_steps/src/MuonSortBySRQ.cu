#include "MuonSortBySRQ.cuh"

__global__ void muon_sort_station_region_quarter(
  const uint* dev_storage_tile_id,
  const uint* dev_atomics_muon,
  uint* dev_permutation_srq)
{
  const size_t event_number = blockIdx.x;
  const auto storage_tile_id = dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  const auto number_of_hits = dev_atomics_muon[event_number];
  auto permutation_srq = dev_permutation_srq +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;

  // Create a permutation according to Muon::MuonTileID::stationRegionQuarter
  const auto get_srq = [&storage_tile_id] (const uint a, const uint b) {
    const auto a_srq = Muon::MuonTileID::stationRegionQuarter(storage_tile_id[a]);
    const auto b_srq = Muon::MuonTileID::stationRegionQuarter(storage_tile_id[b]);

    return (a_srq > b_srq) - (a_srq < b_srq);
  };

  find_permutation(0,
    0,
    number_of_hits,
    permutation_srq,
    get_srq);
}
