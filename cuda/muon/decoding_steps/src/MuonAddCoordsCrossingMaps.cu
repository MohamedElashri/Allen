#include "MuonAddCoordsCrossingMaps.cuh"

__global__ void muon_add_coords_crossing_maps::muon_add_coords_crossing_maps(
  muon_add_coords_crossing_maps::Parameters parameters)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  __shared__ bool used[Muon::Constants::max_numhits_per_event];
  for (uint i = threadIdx.x; i < Muon::Constants::max_numhits_per_event; i += blockDim.x) {
    used[i] = false;
  }

  __syncthreads();

  auto muon_compact_hit = parameters.dev_muon_compact_hit + event_number * Muon::Constants::max_numhits_per_event;
  auto storage_tile_id = parameters.dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  auto storage_tdc_value = parameters.dev_storage_tdc_value + event_number * Muon::Constants::max_numhits_per_event;
  auto current_hit_index = parameters.dev_atomics_muon + number_of_events + event_number;
  auto storage_station_region_quarter_offsets =
    parameters.dev_storage_station_region_quarter_offsets +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
  auto station_ocurrences_sizes = parameters.dev_station_ocurrences_sizes + event_number * Muon::Constants::n_stations;
  const auto base_offset = storage_station_region_quarter_offsets[0];

  for (uint i = threadIdx.x; i < Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
       i += blockDim.x) {

    const auto start_index = storage_station_region_quarter_offsets[i] - base_offset;
    const auto end_index = storage_station_region_quarter_offsets[i + 1] - base_offset;

    if (start_index != end_index) {
      // TODO: We are fetching the first tile ID
      //       We should verify this logic holds (it does not atm)
      const auto tile = Muon::MuonTileID(storage_tile_id[start_index]);
      const auto station = tile.station();
      const auto region = tile.region();

      const auto x1 = getLayoutX(
        parameters.dev_muon_raw_to_hits.get()->muonTables, Muon::MuonTables::stripXTableNumber, station, region);
      const auto y1 = getLayoutY(
        parameters.dev_muon_raw_to_hits.get()->muonTables, Muon::MuonTables::stripXTableNumber, station, region);
      const auto x2 = getLayoutX(
        parameters.dev_muon_raw_to_hits.get()->muonTables, Muon::MuonTables::stripYTableNumber, station, region);
      const auto y2 = getLayoutY(
        parameters.dev_muon_raw_to_hits.get()->muonTables, Muon::MuonTables::stripYTableNumber, station, region);

      Muon::MuonLayout layout_one;
      Muon::MuonLayout layout_two;
      if (x1 > x2) {
        layout_one = Muon::MuonLayout {x1, y1};
        layout_two = Muon::MuonLayout {x2, y2};
      }
      else {
        layout_one = Muon::MuonLayout {x2, y2};
        layout_two = Muon::MuonLayout {x1, y1};
      }

      uint mid_index = start_index;
      unsigned int tmp;
      for (uint j = start_index; j < end_index; ++j) {
        if (Muon::MuonTileID::layout(storage_tile_id[j]) == layout_one) {
          if (mid_index != j) {
            tmp = storage_tile_id[j];
            storage_tile_id[j] = storage_tile_id[mid_index];
            storage_tile_id[mid_index] = tmp;

            tmp = storage_tdc_value[j];
            storage_tdc_value[j] = storage_tdc_value[mid_index];
            storage_tdc_value[mid_index] = tmp;
          }
          mid_index++;
        }
      }

      const int thisGridX = layout_one.xGrid();
      const int thisGridY = layout_one.yGrid();
      const int otherGridX = layout_two.xGrid();
      const int otherGridY = layout_two.yGrid();
      for (uint digitsOneIndex = start_index; digitsOneIndex < mid_index; digitsOneIndex++) {
        const unsigned int keyX = Muon::MuonTileID::nX(storage_tile_id[digitsOneIndex]) * otherGridX / thisGridX;
        const unsigned int keyY = Muon::MuonTileID::nY(storage_tile_id[digitsOneIndex]);

        for (uint digitsTwoIndex = mid_index; digitsTwoIndex < end_index; digitsTwoIndex++) {
          const unsigned int candidateX = Muon::MuonTileID::nX(storage_tile_id[digitsTwoIndex]);
          const unsigned int candidateY =
            Muon::MuonTileID::nY(storage_tile_id[digitsTwoIndex]) * thisGridY / otherGridY;

          if (keyX == candidateX && keyY == candidateY) {
            Muon::MuonTileID padTile(storage_tile_id[digitsOneIndex]);
            const int localCurrentHitIndex = atomicAdd(current_hit_index, 1);

            uint64_t compact_hit =
              (((uint64_t)(digitsOneIndex & 0x7FFF)) << 48) | (((uint64_t)(digitsTwoIndex & 0xFFFF)) << 32) |
              ((thisGridX & 0x3FFF) << 18) | ((otherGridY & 0x3FFF) << 4) |
              (((padTile.id() & Muon::MuonBase::MaskStation) >> Muon::MuonBase::ShiftStation) & 0xF);

            muon_compact_hit[localCurrentHitIndex] = compact_hit;

            atomicAdd(station_ocurrences_sizes + station, 1);

            used[digitsOneIndex] = used[digitsTwoIndex] = true;
          }
        }
      }

      for (auto index = start_index; index < end_index; ++index) {
        if (!used[index]) {
          const auto tile = Muon::MuonTileID(storage_tile_id[index]);
          const int region = tile.region();

          int condition;
          if (tile.station() > (Muon::Constants::n_stations - 3) && region == 0) {
            condition = 0;
          }
          else {
            if (index < mid_index) {
              condition = 1;
            }
            else {
              condition = 2;
            }
          }

          const int localCurrentHitIndex = atomicAdd(current_hit_index, 1);
          const unsigned int uncrossed = 1;

          uint64_t compact_hit = (((uint64_t)(uncrossed & 0x1)) << 63) | (((uint64_t)(index & 0x7FFF)) << 48) |
                                 (condition << 4) |
                                 (((tile.id() & Muon::MuonBase::MaskStation) >> Muon::MuonBase::ShiftStation) & 0xF);
          muon_compact_hit[localCurrentHitIndex] = compact_hit;

          atomicAdd(station_ocurrences_sizes + station, 1);
        }
      }
    }
  }
}
