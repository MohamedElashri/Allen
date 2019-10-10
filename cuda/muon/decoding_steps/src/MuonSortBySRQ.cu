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
  auto permutation_srq = dev_permutation_srq + event_number * Muon::Constants::max_numhits_per_event;

  // Create a permutation according to Muon::MuonTileID::stationRegionQuarter
  const auto get_srq = [&storage_tile_id](const uint a, const uint b) {
    const auto storage_tile_id_a = storage_tile_id[a];
    const auto storage_tile_id_b = storage_tile_id[b];

    const auto a_srq = Muon::MuonTileID::stationRegionQuarter(storage_tile_id_a);
    const auto b_srq = Muon::MuonTileID::stationRegionQuarter(storage_tile_id_b);

    if (a_srq == b_srq) {
      return (storage_tile_id_a > storage_tile_id_b) - (storage_tile_id_a < storage_tile_id_b);
    }

    return (a_srq > b_srq) - (a_srq < b_srq);
  };

  find_permutation(0, 0, number_of_hits, permutation_srq, get_srq);

  __syncthreads();

  __shared__ uint sorted_array[Muon::Constants::max_numhits_per_event];

  // Apply permutation to storage_tile_id
  for (uint i = threadIdx.x; i < number_of_hits; i += blockDim.x) {
    sorted_array[i] = storage_tile_id[permutation_srq[i]];
  }
  __syncthreads();
  for (uint i = threadIdx.x; i < number_of_hits; i += blockDim.x) {
    storage_tile_id[i] = sorted_array[i];
  }

  __syncthreads();

  // Apply permutation to storage_tdc_value
  for (uint i = threadIdx.x; i < number_of_hits; i += blockDim.x) {
    sorted_array[i] = storage_tdc_value[permutation_srq[i]];
  }
  __syncthreads();
  for (uint i = threadIdx.x; i < number_of_hits; i += blockDim.x) {
    storage_tdc_value[i] = sorted_array[i];
  }
}
