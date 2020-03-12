#include "MuonSortByStation.cuh"

__global__ void muon_sort_by_station::muon_sort_by_station(muon_sort_by_station::Parameters parameters)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto number_of_hits = parameters.dev_atomics_muon[number_of_events + event_number];
  const auto station_ocurrences_offset =
    parameters.dev_station_ocurrences_offset + event_number * Muon::Constants::n_stations;
  const auto storage_tile_id = parameters.dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  const auto storage_tdc_value =
    parameters.dev_storage_tdc_value + event_number * Muon::Constants::max_numhits_per_event;
  const auto muon_compact_hit = parameters.dev_muon_compact_hit + event_number * Muon::Constants::max_numhits_per_event;
  auto permutation_station = parameters.dev_permutation_station.get() + event_number * Muon::Constants::max_numhits_per_event;
  auto event_muon_hits = parameters.dev_muon_hits.get() + event_number;

  // Populate number of hits per station and offsets
  // TODO: There should be no need to re-populate this
  for (uint i = threadIdx.x; i < Muon::Constants::n_stations; i += blockDim.x) {
    event_muon_hits->station_offsets[i] = station_ocurrences_offset[i];
    event_muon_hits->number_of_hits_per_station[i] = station_ocurrences_offset[i + 1] - station_ocurrences_offset[i];
  }

  // Create a permutation according to Muon::MuonTileID::stationRegionQuarter
  const auto get_station = [&muon_compact_hit](const uint a, const uint b) {
    const auto muon_compact_hit_a = muon_compact_hit[a] & 0xF;
    const auto muon_compact_hit_b = muon_compact_hit[b] & 0xF;

    return (muon_compact_hit_a > muon_compact_hit_b) - (muon_compact_hit_a < muon_compact_hit_b);
  };

  find_permutation(0, 0, number_of_hits, permutation_station, get_station);

  __syncthreads();

  // Do actual decoding
  for (uint i = threadIdx.x; i < number_of_hits; i += blockDim.x) {
    const uint64_t compact_hit = muon_compact_hit[permutation_station[i]];

    const uint8_t uncrossed = compact_hit >> 63;
    const uint digitsOneIndex_index = (compact_hit >> 48) & 0x7FFF;
    const uint digitsTwoIndex = (compact_hit >> 32) & 0xFFFF;
    const uint thisGridX = (compact_hit >> 18) & 0x3FFF;
    const uint otherGridY_condition = (compact_hit >> 4) & 0x3FFF;

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

      Muon::calcTilePos(parameters.dev_muon_raw_to_hits.get()->muonTables, padTile, x, dx, y, dy, z);
      region = padTile.region();
      id = padTile.id();
      delta_time = storage_tdc_value[digitsOneIndex_index] - storage_tdc_value[digitsTwoIndex];
    }
    else {
      const auto tile = Muon::MuonTileID(storage_tile_id[digitsOneIndex_index]);
      region = tile.region();
      if (otherGridY_condition == 0) {
        calcTilePos(parameters.dev_muon_raw_to_hits.get()->muonTables, tile, x, dx, y, dy, z);
      }
      else if (otherGridY_condition == 1) {
        calcStripXPos(parameters.dev_muon_raw_to_hits.get()->muonTables, tile, x, dx, y, dy, z);
      }
      else {
        calcStripYPos(parameters.dev_muon_raw_to_hits.get()->muonTables, tile, x, dx, y, dy, z);
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
}
