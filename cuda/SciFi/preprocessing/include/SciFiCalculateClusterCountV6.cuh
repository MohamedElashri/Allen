#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsSciFi.cuh"

__global__ void scifi_calculate_cluster_count_v6(
  char* scifi_raw_input,
  uint* scifi_raw_input_offsets,
  const uint* event_list,
  uint* scifi_hit_count,
  char* scifi_geometry);

struct scifi_calculate_cluster_count_v6_t : public GpuAlgorithm {
  constexpr static auto name {"scifi_calculate_cluster_count_v6_t"};
  decltype(gpu_function(scifi_calculate_cluster_count_v6)) function {scifi_calculate_cluster_count_v6};
  using Arguments = std::tuple<
    dev_scifi_raw_input, dev_scifi_raw_input_offsets, dev_scifi_hit_count, dev_event_list>;

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
