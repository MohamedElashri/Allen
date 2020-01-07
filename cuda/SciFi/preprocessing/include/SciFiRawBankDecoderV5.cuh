#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsSciFi.cuh"

__device__ void make_cluster_v5(
  const int hit_index,
  const SciFi::HitCount& hit_count,
  const SciFi::SciFiGeometry& geom,
  uint32_t chan,
  uint8_t fraction,
  uint8_t pseudoSize,
  uint32_t uniqueMat,
  SciFi::Hits& hits);

__global__ void scifi_raw_bank_decoder_v5(
  char* scifi_events,
  uint* scifi_event_offsets,
  const uint* event_list,
  uint* scifi_hit_count,
  uint* scifi_hits,
  char* scifi_geometry,
  const float* dev_inv_clus_res);

struct scifi_raw_bank_decoder_v5_t : public DeviceAlgorithm {
  constexpr static auto name {"scifi_raw_bank_decoder_v5_t"};
  decltype(global_function(scifi_raw_bank_decoder_v5)) function {scifi_raw_bank_decoder_v5};
  using Arguments = std::tuple<
    dev_scifi_raw_input, dev_scifi_raw_input_offsets, dev_scifi_hit_count, dev_scifi_hits, dev_event_list>;

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
