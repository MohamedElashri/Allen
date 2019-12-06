#pragma once

#include "GpuAlgorithm.cuh"
#include "ArgumentsMuon.cuh"
#include "MuonDefinitions.cuh"
#include "FindPermutation.cuh"

__global__ void muon_sort_station_region_quarter(
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  const uint* dev_atomics_muon,
  uint* dev_permutation_srq);

struct muon_sort_station_region_quarter_t : public GpuAlgorithm {
  constexpr static auto name {"muon_sort_station_region_quarter_t"};
  decltype(gpu_function(muon_sort_station_region_quarter)) function {muon_sort_station_region_quarter};
  using Arguments = std::tuple<
    dev_storage_tile_id, dev_storage_tdc_value, dev_atomics_muon, dev_permutation_srq>;

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
