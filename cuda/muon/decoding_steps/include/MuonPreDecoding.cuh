#pragma once

#include "Handler.cuh"
#include "ArgumentsMuon.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

__global__ void muon_pre_decoding(
  const uint* event_list,
  const char* events,
  const unsigned int* offsets,
  const Muon::MuonRawToHits* muon_raw_to_hits,
  uint* dev_storage_station_region_quarter_offsets,
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  uint* dev_atomics_muon);

ALGORITHM(
  muon_pre_decoding,
  muon_pre_decoding_allen_t,
  ARGUMENTS(
    dev_event_list,
    dev_muon_raw,
    dev_muon_raw_offsets,
    dev_muon_raw_to_hits,
    dev_storage_station_region_quarter_offsets,
    dev_storage_tile_id,
    dev_storage_tdc_value,
    dev_atomics_muon))

__global__ void muon_pre_decoding_mep(
  const uint* event_list,
  const char* events,
  const unsigned int* offsets,
  const Muon::MuonRawToHits* muon_raw_to_hits,
  uint* dev_storage_station_region_quarter_offsets,
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  uint* dev_atomics_muon);

ALGORITHM(
  muon_pre_decoding_mep,
  muon_pre_decoding_mep_t,
  ARGUMENTS(
    dev_event_list,
    dev_muon_raw,
    dev_muon_raw_offsets,
    dev_muon_raw_to_hits,
    dev_storage_station_region_quarter_offsets,
    dev_storage_tile_id,
    dev_storage_tdc_value,
    dev_atomics_muon))

XOR_ALGORITHM(muon_pre_decoding_mep_t,
              muon_pre_decoding_allen_t,
              muon_pre_decoding_t)
