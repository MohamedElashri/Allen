#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsSciFi.cuh"

__global__ void scifi_direct_decoder_v4(
  char* scifi_events,
  uint* scifi_event_offsets,
  uint* scifi_hit_count,
  uint* scifi_hits,
  const uint* event_list,
  char* scifi_geometry,
  const float* dev_inv_clus_res);

struct scifi_direct_decoder_v4_t : public DeviceAlgorithm {
  constexpr static auto name {"scifi_direct_decoder_v4_t"};
  decltype(global_function(scifi_direct_decoder_v4)) function {scifi_direct_decoder_v4};
  using Arguments = std::tuple<
    dev_scifi_raw_input, dev_scifi_raw_input_offsets, dev_scifi_hit_count, dev_scifi_hits, dev_event_list>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const {}

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
