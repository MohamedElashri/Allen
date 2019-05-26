#include "MuonAddCoordsCrossingMaps.cuh"

__global__ void muon_add_coords_crossing_maps(
  uint* dev_storage_station_region_quarter_offsets,
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  uint* dev_atomics_muon,
  uint* dev_permutation_srq,
  Muon::MuonRawToHits* muon_raw_to_hits,
  Muon::HitsSoA* muon_hits)
{
  __shared__ bool used[Muon::Constants::max_numhits_per_event];
  for (int i=threadIdx.x; i<Muon::Constants::max_numhits_per_event; i+=blockDim.x) {
    used[i] = false;
  }

  // Due to used
  __syncthreads();

  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  auto event_muon_hits = muon_hits + event_number;
  auto storage_tile_id = dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  auto storage_tdc_value = dev_storage_tdc_value + event_number * Muon::Constants::max_numhits_per_event;
  auto current_hit_index = dev_atomics_muon + number_of_events + event_number;
  auto storage_station_region_quarter_offsets = dev_storage_station_region_quarter_offsets +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;

  muon_raw_to_hits->addCoordsCrossingMap(
      storage_tile_id,
      storage_tdc_value,
      used,
      storage_station_region_quarter_offsets[threadIdx.x],
      storage_station_region_quarter_offsets[threadIdx.x + 1],
      event_muon_hits,
      *current_hit_index
  );
}
