#pragma once

#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ClusteringDefinitions.cuh"

__global__ void velo_estimate_input_size(
  char* dev_raw_input,
  uint* dev_raw_input_offsets,
  uint* dev_estimated_input_size,
  uint* dev_module_candidate_num,
  uint32_t* dev_cluster_candidates,
  const uint* dev_event_list,
  uint8_t* dev_velo_candidate_ks);

struct velo_estimate_input_size_t : public GpuAlgorithm {
  constexpr static auto name {"velo_estimate_input_size_t"};
  decltype(gpu_function(velo_estimate_input_size)) algorithm {velo_estimate_input_size};
  using Arguments = std::tuple<
    dev_velo_raw_input,
    dev_velo_raw_input_offsets,
    dev_estimated_input_size,
    dev_module_cluster_num,
    dev_module_candidate_num,
    dev_cluster_candidates,
    dev_event_list>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void visit(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
