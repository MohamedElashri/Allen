#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace decode_retinaclusters {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_total_number_of_velo_clusters_t, uint), host_total_number_of_velo_clusters),
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (DEVICE_INPUT(dev_velo_retina_raw_input_t, char), dev_velo_retina_raw_input),
    (DEVICE_INPUT(dev_velo_retina_raw_input_offsets_t, uint), dev_velo_retina_raw_input_offsets),
    (DEVICE_INPUT(dev_offsets_each_sensor_size_t, uint), dev_offsets_each_sensor_size),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_OUTPUT(dev_module_cluster_num_t, uint), dev_module_pair_cluster_num),
    (DEVICE_OUTPUT(dev_offsets_module_pair_cluster_t, uint), dev_offsets_module_pair_cluster),
    (DEVICE_OUTPUT(dev_velo_cluster_container_t, char), dev_velo_cluster_container),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim_prop))

  __global__ void decode_retinaclusters(
    Parameters parameters,
    const VeloGeometry* dev_velo_geometry);

  __global__ void decode_retinaclusters_mep(
    Parameters parameters,
    const VeloGeometry* dev_velo_geometry);

  struct decode_retinaclusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{8, 32, 1}}};
  };
} // namespace decode_retinaclusters
