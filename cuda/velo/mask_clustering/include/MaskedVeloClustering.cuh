#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"

__global__ void velo_masked_clustering(
  char* dev_raw_input,
  uint* dev_raw_input_offsets,
  uint* dev_module_cluster_start,
  uint* dev_module_cluster_num,
  uint* dev_event_candidate_num,
  uint* dev_cluster_candidates,
  uint32_t* dev_velo_cluster_container,
  const uint* dev_event_list,
  const VeloGeometry* dev_velo_geometry,
  uint8_t* dev_velo_sp_patterns,
  float* dev_velo_sp_fx,
  float* dev_velo_sp_fy);

struct velo_masked_clustering_t : public GpuAlgorithm {
  constexpr static auto name {"velo_masked_clustering_t"};
  decltype(gpu_function(velo_masked_clustering)) function {velo_masked_clustering};
  using Arguments = std::tuple<
    dev_velo_raw_input,
    dev_velo_raw_input_offsets,
    dev_estimated_input_size,
    dev_module_cluster_num,
    dev_module_candidate_num,
    dev_cluster_candidates,
    dev_velo_cluster_container,
    dev_event_list>;

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
