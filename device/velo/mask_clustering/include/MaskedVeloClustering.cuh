#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "VeloTools.cuh"

namespace velo_masked_clustering {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned), host_total_number_of_velo_clusters),
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_velo_raw_input_t, char), dev_velo_raw_input),
    (DEVICE_INPUT(dev_velo_raw_input_offsets_t, unsigned), dev_velo_raw_input_offsets),
    (DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned), dev_offsets_estimated_input_size),
    (DEVICE_INPUT(dev_module_candidate_num_t, unsigned), dev_module_pair_candidate_num),
    (DEVICE_INPUT(dev_cluster_candidates_t, unsigned), dev_cluster_candidates),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_candidates_offsets_t, unsigned), dev_candidates_offsets),
    (DEVICE_OUTPUT(dev_module_cluster_num_t, unsigned), dev_module_pair_cluster_num),
    (DEVICE_OUTPUT(dev_velo_cluster_container_t, char), dev_velo_cluster_container),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

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

  struct velo_masked_clustering_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_masked_clustering
