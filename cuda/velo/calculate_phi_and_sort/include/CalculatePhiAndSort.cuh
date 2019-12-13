#pragma once

#include <cstdint>
#include <cassert>
#include "CudaCommon.h"
#include "VeloDefinitions.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsVelo.cuh"

__device__ void calculate_phi(
  const uint* module_hitStarts,
  const uint* module_hitNums,
  const float* hit_Xs,
  const float* hit_Ys,
  float* hit_Phis,
  uint* hit_permutations,
  float* shared_hit_phis);

__device__ void sort_by_phi(
  const uint event_hit_start,
  const uint event_number_of_hits,
  float* hit_Xs,
  float* hit_Ys,
  float* hit_Zs,
  uint* hit_IDs,
  int32_t* hit_temp,
  uint* hit_permutations);

__global__ void velo_calculate_phi_and_sort(
  uint* dev_module_cluster_start,
  uint* dev_module_cluster_num,
  uint32_t* dev_velo_cluster_container,
  uint* dev_hit_permutations);

struct velo_calculate_phi_and_sort_t : public GpuAlgorithm {
  constexpr static auto name {"velo_calculate_phi_and_sort_t"};
  decltype(gpu_function(velo_calculate_phi_and_sort)) function {velo_calculate_phi_and_sort};
  using Arguments =
    std::tuple<dev_estimated_input_size, dev_module_cluster_num, dev_velo_cluster_container, dev_hit_permutation>;

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