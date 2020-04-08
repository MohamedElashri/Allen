#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace velo_masked_clustering {
  struct Parameters {
    HOST_INPUT(host_total_number_of_velo_clusters_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_velo_raw_input_t, char) dev_velo_raw_input;
    DEVICE_INPUT(dev_velo_raw_input_offsets_t, uint) dev_velo_raw_input_offsets;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_candidate_num_t, uint) dev_module_candidate_num;
    DEVICE_INPUT(dev_cluster_candidates_t, uint) dev_cluster_candidates;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_candidates_offsets_t, uint) dev_candidates_offsets;
    DEVICE_OUTPUT(dev_module_cluster_num_t, uint) dev_module_cluster_num;
    DEVICE_OUTPUT(dev_velo_cluster_container_t, char) dev_velo_cluster_container;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  // Function
  __global__ void velo_masked_clustering(
    Parameters parameters,
    const VeloGeometry* dev_velo_geometry,
    const uint8_t* dev_velo_sp_patterns,
    const float* dev_velo_sp_fx,
    const float* dev_velo_sp_fy);

  __global__ void velo_masked_clustering_mep(
    Parameters parameters,
    const VeloGeometry* dev_velo_geometry,
    const uint8_t* dev_velo_sp_patterns,
    const float* dev_velo_sp_fx,
    const float* dev_velo_sp_fy);

  template<typename T, char... S>
  struct velo_masked_clustering_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(velo_masked_clustering)) function {velo_masked_clustering};
    decltype(global_function(velo_masked_clustering_mep)) function_mep {velo_masked_clustering_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_module_cluster_num_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Velo::Constants::n_modules);
      set_size<dev_velo_cluster_container_t>(arguments,
        value<host_total_number_of_velo_clusters_t>(arguments) * Velo::Clusters::element_size);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_module_cluster_num_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters{
          begin<dev_velo_raw_input_t>(arguments),
          begin<dev_velo_raw_input_offsets_t>(arguments),
          begin<dev_offsets_estimated_input_size_t>(arguments),
          begin<dev_module_candidate_num_t>(arguments),
          begin<dev_cluster_candidates_t>(arguments),
          begin<dev_event_list_t>(arguments),
          begin<dev_candidates_offsets_t>(arguments),
          begin<dev_module_cluster_num_t>(arguments),
          begin<dev_velo_cluster_container_t>(arguments)
        };

        // Selector from layout
      if (runtime_options.mep_layout) {
        function_mep(dim3(begin<host_number_of_selected_events_t>(arguments)[0]), property<block_dim_t>(), cuda_stream)(
          parameters,
          constants.dev_velo_geometry,
          constants.dev_velo_sp_patterns.data(),
          constants.dev_velo_sp_fx.data(),
          constants.dev_velo_sp_fy.data());
      } else {
        function(dim3(begin<host_number_of_selected_events_t>(arguments)[0]), property<block_dim_t>(), cuda_stream)(
          parameters,
          constants.dev_velo_geometry,
          constants.dev_velo_sp_patterns.data(),
          constants.dev_velo_sp_fx.data(),
          constants.dev_velo_sp_fy.data());
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_masked_clustering
