#include "MuonSortByStation.cuh"

__global__ void muon_sort_by_station(
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  const uint* dev_atomics_muon,
  uint* dev_permutation_station,
  Muon::HitsSoA* muon_hits,
  uint* dev_station_ocurrences_offset,
  const uint64_t* dev_muon_compact_hit,
  Muon::MuonRawToHits* muon_raw_to_hits)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto number_of_hits = dev_atomics_muon[number_of_events + event_number];
  const auto station_ocurrences_offset = dev_station_ocurrences_offset + event_number * Muon::Constants::n_stations;
  const auto storage_tile_id = dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  const auto storage_tdc_value = dev_storage_tdc_value + event_number * Muon::Constants::max_numhits_per_event;
  auto permutation_station = dev_permutation_station + event_number * Muon::Constants::max_numhits_per_event;
  auto event_muon_hits = muon_hits + event_number;

  // Populate number of hits per station and offsets
  // TODO: There should be no need to re-populate this
  for (int i=threadIdx.x; i<number_of_hits; i+=blockDim.x) {
    event_muon_hits->station_offsets[i] = station_ocurrences_offset[i];
    event_muon_hits->number_of_hits_per_station[i] = station_ocurrences_offset[i+1] - 
      station_ocurrences_offset[i];
  }

  // Create a permutation according to Muon::MuonTileID::stationRegionQuarter
  const auto get_station = [&station_ocurrences_offset] (const uint a, const uint b) {
    const auto station_ocurrences_offset_a = station_ocurrences_offset[a];
    const auto station_ocurrences_offset_b = station_ocurrences_offset[b];

    return (station_ocurrences_offset_a > station_ocurrences_offset_b)
      - (station_ocurrences_offset_a < station_ocurrences_offset_b);
  };

  find_permutation(0,
    0,
    number_of_hits,
    permutation_station,
    get_station);

  __syncthreads();

  __shared__ uint64_t sorted_array [Muon::Constants::max_numhits_per_event];

  // Apply permutation to shared memory buffer
  for (int i=threadIdx.x; i<number_of_hits; i+=blockDim.x) {
    sorted_array[i] = dev_muon_compact_hit[permutation_station[i]];
  }

  __syncthreads();

  // Do actual decoding
  for (int i=threadIdx.x; i<number_of_hits; i+=blockDim.x) {
    const uint64_t compact_hit = sorted_array[i];

    const uint8_t uncrossed = compact_hit >> 63;
    const uint digitsOneIndex_index = (compact_hit >> 48) & 0x7FFF;
    const uint digitsTwoIndex = (compact_hit >> 32) & 0xFFFF;
    const uint thisGridX = (compact_hit >> 16) & 0xFFFF;
    const uint otherGridY_condition = compact_hit & 0xFFFF;

    float x = 0.f;
    float dx = 0.f;
    float y = 0.f;
    float dy = 0.f;
    float z = 0.f;
    float dz = 0.f;
    int delta_time;
    int id;
    int region;

    if (!uncrossed) {
      Muon::MuonTileID padTile(storage_tile_id[digitsOneIndex_index]);
      padTile.setY(Muon::MuonTileID::nY(storage_tile_id[digitsTwoIndex]));
      padTile.setLayout(Muon::MuonLayout(thisGridX, otherGridY_condition));
      Muon::calcTilePos(muon_raw_to_hits->muonTables, padTile, x, dx, y, dy, z);
      region = padTile.region();
      id = padTile.id();
      delta_time = storage_tdc_value[digitsOneIndex_index] - storage_tdc_value[digitsTwoIndex];
    } else {
      const auto tile = Muon::MuonTileID(storage_tile_id[digitsOneIndex_index]);
      region = tile.region();
      if (otherGridY_condition == 0) {
        calcTilePos(muon_raw_to_hits->muonTables, tile, x, dx, y, dy, z);
      } else if (otherGridY_condition == 1) {
        calcStripXPos(muon_raw_to_hits->muonTables, tile, x, dx, y, dy, z);
      } else {
        calcStripYPos(muon_raw_to_hits->muonTables, tile, x, dx, y, dy, z);
      }
      id = tile.id();
      delta_time = storage_tdc_value[digitsOneIndex_index];
    }

    setAtIndex(
      event_muon_hits,
      i,
      id,
      x,
      dx,
      y,
      dy,
      z,
      dz,
      uncrossed,
      storage_tdc_value[digitsOneIndex_index],
      delta_time,
      0,
      region);
  }

  // // Print
  // __syncthreads();
  // if (blockIdx.x == 0 && threadIdx.x == 0) {
  //   for (int i=0; i<number_of_hits; ++i) {
  //     printf("(%i, %i, %i), ",
  //       storage_tile_id[i],
  //       storage_tdc_value[i],
  //       Muon::MuonTileID::stationRegionQuarter(storage_tile_id[i]));
  //   }
  // }
}
