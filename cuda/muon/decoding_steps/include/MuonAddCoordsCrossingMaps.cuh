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
  uint* dev_permutation_srq,
  Muon::MuonRawToHits* muon_raw_to_hits,
  Muon::HitsSoA* muon_hits);

ALGORITHM(
  muon_add_coords_crossing_maps,
  muon_add_coords_crossing_maps_t,
  ARGUMENTS(dev_storage_station_region_quarter_offsets, dev_storage_tile_id,
    dev_storage_tdc_value, dev_atomics_muon, dev_permutation_srq, dev_muon_hits,
    dev_muon_raw_to_hits))
