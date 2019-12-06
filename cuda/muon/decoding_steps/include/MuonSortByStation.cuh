#pragma once

#include "GpuAlgorithm.cuh"
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

struct muon_sort_by_station_t : public GpuAlgorithm {
  constexpr static auto name {"muon_sort_by_station_t"};
  decltype(gpu_function(muon_sort_by_station)) function {muon_sort_by_station};
  using Arguments = std::tuple<
    dev_storage_tile_id,
    dev_storage_tdc_value,
    dev_atomics_muon,
    dev_permutation_station,
    dev_muon_hits,
    dev_station_ocurrences_offset,
    dev_muon_compact_hit,
    dev_muon_raw_to_hits>;

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
