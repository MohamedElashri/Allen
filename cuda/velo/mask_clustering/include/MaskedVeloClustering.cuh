#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "GpuAlgorithm.cuh"

namespace velo_masked_clustering {
  // Arguments
  struct dev_velo_raw_input_t : input_datatype<char> {};
  struct dev_velo_raw_input_offsets_t : input_datatype<uint> {};
  struct dev_estimated_input_size_t : input_datatype<uint> {};
  struct dev_module_candidate_num_t : input_datatype<uint> {};
  struct dev_cluster_candidates_t : input_datatype<uint> {};
  struct dev_event_list_t : input_datatype<uint> {};
  struct dev_module_cluster_num_t : output_datatype<uint> {};
  struct dev_velo_cluster_container_t : output_datatype<float> {};

  // Function
  __global__ void velo_masked_clustering(
    dev_velo_raw_input_t dev_velo_raw_input,
    dev_velo_raw_input_offsets_t dev_velo_raw_input_offsets,
    dev_estimated_input_size_t dev_estimated_input_size,
    dev_module_cluster_num_t dev_module_cluster_num,
    dev_module_candidate_num_t dev_module_candidate_num,
    dev_cluster_candidates_t dev_cluster_candidates,
    dev_velo_cluster_container_t dev_velo_cluster_container,
    dev_event_list_t dev_event_list,
    const VeloGeometry* dev_velo_geometry,
    uint8_t* dev_velo_sp_patterns,
    float* dev_velo_sp_fx,
    float* dev_velo_sp_fy);

  template<typename Arguments>
  struct velo_masked_clustering_t : public GpuAlgorithm {
    constexpr static auto name {"velo_masked_clustering_t"};
    decltype(gpu_function(velo_masked_clustering)) function {velo_masked_clustering};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_module_cluster_num_t>(
        arguments, host_buffers.host_number_of_selected_events[0] * Velo::Constants::n_modules);
      set_size<dev_velo_cluster_container_t>(arguments, 6 * host_buffers.host_total_number_of_velo_clusters[0]);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemsetAsync(
        offset<dev_module_cluster_num_t>(arguments),
        0,
        size<dev_module_cluster_num_t>(arguments),
        cuda_stream));
      
      function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
        offset<dev_velo_raw_input_t>(arguments),
        offset<dev_velo_raw_input_offsets_t>(arguments),
        offset<dev_estimated_input_size_t>(arguments),
        offset<dev_module_cluster_num_t>(arguments),
        offset<dev_module_candidate_num_t>(arguments),
        offset<dev_cluster_candidates_t>(arguments),
        offset<dev_velo_cluster_container_t>(arguments),
        offset<dev_event_list_t>(arguments),
        constants.dev_velo_geometry,
        constants.dev_velo_sp_patterns.data(),
        constants.dev_velo_sp_fx.data(),
        constants.dev_velo_sp_fy.data());
    }
  };
} // namespace velo_masked_clustering