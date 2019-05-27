#include "MuonSortBySRQ.cuh"

__global__ void muon_sort_station_region_quarter(
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  const uint* dev_atomics_muon,
  uint* dev_permutation_srq)
{
  const auto event_number = blockIdx.x;
  const auto storage_tile_id = dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  const auto storage_tdc_value = dev_storage_tdc_value + event_number * Muon::Constants::max_numhits_per_event;
  const auto number_of_hits = dev_atomics_muon[event_number];
  auto permutation_srq = dev_permutation_srq +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;

  // Create a permutation according to Muon::MuonTileID::stationRegionQuarter
  const auto get_srq = [&storage_tile_id] (const uint a, const uint b) {
    const auto a_srq = Muon::MuonTileID::stationRegionQuarter(storage_tile_id[a]);
    const auto b_srq = Muon::MuonTileID::stationRegionQuarter(storage_tile_id[b]);

    return (a_srq > b_srq) - (a_srq < b_srq);
  };

  //  + ((a_srq == b_srq) * )
  // const unsigned int x1 = getLayoutX(muonTables, MuonTables::stripXTableNumber, station, region);
  // const unsigned int x2 = getLayoutX(muonTables, MuonTables::stripYTableNumber, station, region);

  find_permutation(0,
    0,
    number_of_hits,
    permutation_srq,
    get_srq);

  __syncthreads();

  __shared__ uint sorted_array[Muon::Constants::max_numhits_per_event];

  // Apply permutation to storage_tile_id
  for (int i=threadIdx.x; i<number_of_hits; i+=blockDim.x) {
    sorted_array[i] = storage_tile_id[permutation_srq[i]];
  }
  __syncthreads();
  for (int i=threadIdx.x; i<number_of_hits; i+=blockDim.x) {
    storage_tile_id[i] = sorted_array[i];
  }

  __syncthreads();

  // Apply permutation to storage_tdc_value
  for (int i=threadIdx.x; i<number_of_hits; i+=blockDim.x) {
    sorted_array[i] = storage_tdc_value[permutation_srq[i]];
  }
  __syncthreads();
  for (int i=threadIdx.x; i<number_of_hits; i+=blockDim.x) {
    storage_tdc_value[i] = sorted_array[i];
  }

  // // Print
  // __syncthreads();
  // if (threadIdx.x == 0) {
  //   for (int i=0; i<number_of_hits; ++i) {
  //     printf("(%i, %i, %i), ",
  //       storage_tile_id[i],
  //       storage_tdc_value[i],
  //       Muon::MuonTileID::stationRegionQuarter(storage_tile_id[i]));
  //   }
  // }
}
