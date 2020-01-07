#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace velo_masked_clustering {
  struct Arguments {
    HOST_INPUT(host_total_number_of_velo_clusters_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_velo_raw_input_t, char) dev_velo_raw_input;
    DEVICE_INPUT(dev_velo_raw_input_offsets_t, uint) dev_velo_raw_input_offsets;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_candidate_num_t, uint) dev_module_candidate_num;
    DEVICE_INPUT(dev_cluster_candidates_t, uint) dev_cluster_candidates;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_module_cluster_num_t, uint) dev_module_cluster_num;
    DEVICE_OUTPUT(dev_velo_cluster_container_t, uint32_t) dev_velo_cluster_container;
  };

  // Function
  __global__ void velo_masked_clustering(
    Arguments arguments,
    const VeloGeometry* dev_velo_geometry,
    uint8_t* dev_velo_sp_patterns,
    float* dev_velo_sp_fx,
    float* dev_velo_sp_fy);

  template<typename T>
  struct velo_masked_clustering_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"velo_masked_clustering_t"};
    decltype(global_function(velo_masked_clustering)) function {velo_masked_clustering};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_module_cluster_num_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Velo::Constants::n_modules);
      set_size<dev_velo_cluster_container_t>(arguments, 4 * value<host_total_number_of_velo_clusters_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
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
      
      function(dim3(offset<host_number_of_selected_events_t>(arguments)[0]), block_dimension(), cuda_stream)(
        Arguments{
          offset<dev_velo_raw_input_t>(arguments),
          offset<dev_velo_raw_input_offsets_t>(arguments),
          offset<dev_offsets_estimated_input_size_t>(arguments),
          offset<dev_module_candidate_num_t>(arguments),
          offset<dev_cluster_candidates_t>(arguments),
          offset<dev_event_list_t>(arguments),
          offset<dev_module_cluster_num_t>(arguments),
          offset<dev_velo_cluster_container_t>(arguments)
        },
        constants.dev_velo_geometry,
        constants.dev_velo_sp_patterns.data(),
        constants.dev_velo_sp_fx.data(),
        constants.dev_velo_sp_fy.data());
    }
  };
} // namespace velo_masked_clustering