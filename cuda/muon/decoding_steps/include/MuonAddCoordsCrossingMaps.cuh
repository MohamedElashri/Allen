#pragma once

#include "DeviceAlgorithm.cuh"
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

struct muon_add_coords_crossing_maps_t : public DeviceAlgorithm {
  constexpr static auto name {"muon_add_coords_crossing_maps_t"};
  decltype(global_function(muon_add_coords_crossing_maps)) function {muon_add_coords_crossing_maps};
  using Arguments = std::tuple<
    dev_storage_station_region_quarter_offsets,
    dev_storage_tile_id,
    dev_storage_tdc_value,
    dev_atomics_muon,
    dev_muon_hits,
    dev_muon_raw_to_hits,
    dev_station_ocurrences_offset,
    dev_muon_compact_hit>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
