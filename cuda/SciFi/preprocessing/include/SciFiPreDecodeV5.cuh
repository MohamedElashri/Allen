#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsSciFi.cuh"

__device__ void store_sorted_cluster_reference_v5(
  const SciFi::HitCount& hit_count,
  const uint32_t uniqueMat,
  const uint32_t chan,
  const uint32_t* shared_mat_offsets,
  uint32_t* shared_mat_count,
  const int raw_bank,
  const int it,
  const int condition_1,
  const int condition_2,
  const int delta,
  SciFi::Hits& hits);

__global__ void scifi_pre_decode_v5(
  char* scifi_events,
  uint* scifi_event_offsets,
  const uint* event_list,
  uint* scifi_hit_count,
  uint* scifi_hits,
  char* scifi_geometry,
  const float* dev_inv_clus_res);

struct scifi_pre_decode_v5_t : public GpuAlgorithm {
  constexpr static auto name {"scifi_pre_decode_v5_t"};
  decltype(gpu_function(scifi_pre_decode_v5)) function {scifi_pre_decode_v5};
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
