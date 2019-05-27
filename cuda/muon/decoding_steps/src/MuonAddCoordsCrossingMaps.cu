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
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  auto event_muon_hits = muon_hits + event_number;
  auto storage_tile_id = dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  auto storage_tdc_value = dev_storage_tdc_value + event_number * Muon::Constants::max_numhits_per_event;
  auto current_hit_index = dev_atomics_muon + number_of_events + event_number;
  auto storage_station_region_quarter_offsets =
    dev_storage_station_region_quarter_offsets +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
  const auto base_offset = storage_station_region_quarter_offsets[0];

  for (int i = threadIdx.x; i < Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
       i += blockDim.x) {

    const auto start_index = storage_station_region_quarter_offsets[i] - base_offset;
    const auto end_index = storage_station_region_quarter_offsets[i + 1] - base_offset;

    // TODO: We are fetching the first tile ID
    //       We should verify this logic holds (it does not atm)
    const auto tile = Muon::MuonTileID(storage_tile_id[start_index]);
    const auto station = tile.station();
    const auto region = tile.region();

    const auto x1 = getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, station, region);
    const auto y1 = getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, station, region);
    const auto x2 = getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, station, region);
    const auto y2 = getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, station, region);

    Muon::MuonLayout layout_one;
    if (x1 > x2) {
      layout_one = Muon::MuonLayout {x1, y1};
    }
    else {
      layout_one = Muon::MuonLayout {x2, y2};
    }

    for (int j = start_index; j < end_index; ++j) {
      float x = 0.f, dx = 0.f, y = 0.f, dy = 0.f, z = 0.f, dz = 0.f;
      const auto tile = Muon::MuonTileID(storage_tile_id[j]);
      const auto region = tile.region();
      if (tile.station() > (Muon::Constants::n_stations - 3) && region == 0) {
        calcTilePos(muon_raw_to_hits->muonTables, tile, x, dx, y, dy, z);
      }
      else {
        if (Muon::MuonTileID::layout(storage_tile_id[j]) == layout_one) {
          calcStripXPos(muon_raw_to_hits->muonTables, tile, x, dx, y, dy, z);
        }
        else {
          calcStripYPos(muon_raw_to_hits->muonTables, tile, x, dx, y, dy, z);
        }
      }
      const uint uncrossed = 1;
      const int clusterSize = 0;
      const auto localCurrentHitIndex = atomicAdd(current_hit_index, 1);

      setAtIndex(
        event_muon_hits,
        localCurrentHitIndex,
        tile.id(),
        x,
        dx,
        y,
        dy,
        z,
        dz,
        uncrossed,
        storage_tdc_value[j],
        storage_tdc_value[j],
        clusterSize,
        region);
    }
  }
}
