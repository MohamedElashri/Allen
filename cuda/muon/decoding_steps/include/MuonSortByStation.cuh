#pragma once

#include "Handler.cuh"
#include "ArgumentsMuon.cuh"
#include "MuonDefinitions.cuh"
#include "FindPermutation.cuh"

__global__ void muon_sort_by_station(
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  const uint* dev_atomics_muon,
  uint* dev_permutation_station,
  Muon::HitsSoA* muon_hits,
  uint* dev_station_ocurrences_offset,
  const uint64_t* dev_muon_compact_hit,
  Muon::MuonRawToHits* muon_raw_to_hits);

ALGORITHM(
  muon_sort_by_station,
  muon_sort_by_station_t,
  ARGUMENTS(
    dev_storage_tile_id,
    dev_storage_tdc_value,
    dev_atomics_muon,
    dev_permutation_station,
    dev_muon_hits,
    dev_station_ocurrences_offset,
    dev_muon_compact_hit,
    dev_muon_raw_to_hits))
