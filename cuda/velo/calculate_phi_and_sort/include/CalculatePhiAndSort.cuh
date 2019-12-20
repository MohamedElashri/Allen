#pragma once

#include <cstdint>
#include <cassert>
#include "CudaCommon.h"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "GpuAlgorithm.cuh"

namespace velo_calculate_phi_and_sort {
  // Arguments
  HOST_INPUT(host_number_of_selected_events_t, uint)
  HOST_INPUT(host_total_number_of_velo_clusters_t, uint)
  DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint)
  DEVICE_INPUT(dev_module_cluster_num_t, uint)
  DEVICE_INPUT(dev_velo_cluster_container_t, uint32_t)
  DEVICE_OUTPUT(dev_sorted_velo_cluster_container_t, uint32_t)
  DEVICE_OUTPUT(dev_hit_permutation_t, uint)
  DEVICE_OUTPUT(dev_hit_phi_t, float)

  __device__ void calculate_phi(
    const uint* module_hitStarts,
    const uint* module_hitNums,
    const Velo::Clusters<const uint32_t>& velo_cluster_container,
    float* hit_Phis,
    uint* hit_permutations,
    float* shared_hit_phis);

  __device__ void sort_by_phi(
    const uint event_hit_start,
    const uint event_number_of_hits,
    const Velo::Clusters<const uint32_t>& velo_cluster_container,
    Velo::Clusters<uint32_t>& velo_sorted_cluster_container,
    uint* hit_permutations);

  __global__ void velo_calculate_phi_and_sort(
    dev_offsets_estimated_input_size_t,
    dev_module_cluster_num_t,
    dev_velo_cluster_container_t,
    dev_sorted_velo_cluster_container_t,
    dev_hit_permutation_t,
    dev_hit_phi_t);

  template<typename Arguments>
  struct velo_calculate_phi_and_sort_t : public DeviceAlgorithm {
    constexpr static auto name {"velo_calculate_phi_and_sort_t"};
    decltype(global_function(velo_calculate_phi_and_sort)) function {velo_calculate_phi_and_sort};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_sorted_velo_cluster_container_t>(arguments, size<dev_velo_cluster_container_t>(arguments) / sizeof(uint32_t));
      set_size<dev_hit_permutation_t>(arguments, value<host_total_number_of_velo_clusters_t>(arguments));
      set_size<dev_hit_phi_t>(arguments, value<host_total_number_of_velo_clusters_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      cudaCheck(cudaMemsetAsync(
        offset<dev_hit_permutation_t>(arguments),
        0,
        size<dev_hit_permutation_t>(arguments),
        cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        offset<dev_offsets_estimated_input_size_t>(arguments),
        offset<dev_module_cluster_num_t>(arguments),
        offset<dev_velo_cluster_container_t>(arguments),
        offset<dev_sorted_velo_cluster_container_t>(arguments),
        offset<dev_hit_permutation_t>(arguments),
        offset<dev_hit_phi_t>(arguments));
    }
  };
} // namespace velo_calculate_phi_and_sort