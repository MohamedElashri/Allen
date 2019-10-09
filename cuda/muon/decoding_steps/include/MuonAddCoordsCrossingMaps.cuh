#pragma once

#include "Handler.cuh"
#include "ArgumentsMuon.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

__global__ void muon_add_coords_crossing_maps(
  uint* dev_storage_station_region_quarter_offsets,
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  uint* dev_atomics_muon,
  Muon::MuonRawToHits* muon_raw_to_hits,
  uint64_t* dev_muon_compact_hit,
  uint* dev_station_ocurrences_offset);

ALGORITHM(
  muon_add_coords_crossing_maps,
  muon_add_coords_crossing_maps_t,
  ARGUMENTS(
    dev_storage_station_region_quarter_offsets,
    dev_storage_tile_id,
    dev_storage_tdc_value,
    dev_atomics_muon,
    dev_muon_hits,
    dev_muon_raw_to_hits,
    dev_station_ocurrences_offset,
    dev_muon_compact_hit))
