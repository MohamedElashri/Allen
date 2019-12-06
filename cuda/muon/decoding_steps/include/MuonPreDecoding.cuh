#pragma once

#include "GpuAlgorithm.cuh"
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

struct muon_pre_decoding_t : public GpuAlgorithm {
  constexpr static auto name {"muon_pre_decoding_t"};
  decltype(gpu_function(muon_pre_decoding)) function {muon_pre_decoding};
  using Arguments = std::tuple<
    dev_event_list,
    dev_muon_raw,
    dev_muon_raw_offsets,
    dev_muon_raw_to_hits,
    dev_storage_station_region_quarter_offsets,
    dev_storage_tile_id,
    dev_storage_tdc_value,
    dev_atomics_muon>;

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
