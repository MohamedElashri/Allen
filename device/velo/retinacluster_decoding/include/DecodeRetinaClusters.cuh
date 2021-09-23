/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "VeloTools.cuh"

namespace decode_retinaclusters {
  struct Parameters {
    HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned) host_total_number_of_velo_clusters;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_velo_retina_raw_input_t, char) dev_velo_retina_raw_input;
    DEVICE_INPUT(dev_velo_retina_raw_input_offsets_t, unsigned) dev_velo_retina_raw_input_offsets;
    DEVICE_INPUT(dev_offsets_each_sensor_size_t, unsigned) dev_offsets_each_sensor_size;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_module_cluster_num_t, unsigned) dev_module_pair_cluster_num;
    DEVICE_OUTPUT(dev_offsets_module_pair_cluster_t, unsigned) dev_offsets_module_pair_cluster;
    DEVICE_OUTPUT(dev_velo_cluster_container_t, char) dev_velo_cluster_container;
    DEVICE_OUTPUT(
      dev_velo_clusters_t,
      Velo::Clusters,
      dev_velo_cluster_container_t,
      dev_module_cluster_num_t,
      dev_number_of_events_t,
      dev_offsets_module_pair_cluster_t)
    dev_velo_clusters;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim_prop;
  };

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
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{4, 32, 1}}};
  };
} // namespace decode_retinaclusters
