/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "VeloTools.cuh"

namespace decode_retinaclusters {
  struct Parameters {
    HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned) host_total_number_of_velo_clusters;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_velo_retina_raw_input_t, char) dev_velo_retina_raw_input;
    DEVICE_INPUT(dev_velo_retina_raw_input_offsets_t, unsigned) dev_velo_retina_raw_input_offsets;
    DEVICE_INPUT(dev_offsets_each_sensor_size_t, unsigned) dev_offsets_each_sensor_size;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_module_cluster_num_t, unsigned) dev_module_pair_cluster_num;
    DEVICE_OUTPUT(dev_offsets_module_pair_cluster_t, unsigned) dev_offsets_module_pair_cluster;
    DEVICE_OUTPUT(dev_velo_cluster_container_t, char) dev_velo_cluster_container;
    DEVICE_OUTPUT(dev_hit_permutations_t, unsigned) dev_hit_permutations;
    DEVICE_OUTPUT(dev_hit_sorting_key_t, int64_t) dev_hit_sorting_key;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_clusters_t,
      DEPENDENCIES(
        dev_velo_cluster_container_t,
        dev_module_cluster_num_t,
        dev_number_of_events_t,
        dev_offsets_module_pair_cluster_t),
      Velo::Clusters)
    dev_velo_clusters;
    PROPERTY(block_dim_x_calculate_key_t, "block_dim_x_calculate_key", "block dim x of calculate_key", unsigned)
    block_dim_x_calculate_key;
    PROPERTY(
      block_dim_calculate_permutations_t,
      "block_dim_calculate_permutations",
      "block dims of calculate permutations",
      DeviceDimensions)
    block_dim_calculate_permutations;
    PROPERTY(block_dim_x_decode_retina_t, "block_dim_x_decode_retina", "block dim x of decode retina sorted", unsigned)
    block_dim_x_decode_retina;
  };

  // Define postconditions
  struct cluster_container_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct decode_retinaclusters_t : public DeviceAlgorithm, Parameters {

    using contracts = std::tuple<cluster_container_checks>;

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
    Property<block_dim_x_calculate_key_t> m_block_dim_x_calculate_key {this, 256};
    Property<block_dim_calculate_permutations_t> m_block_dim_calculate_permutations {this, {{2, 128, 1}}};
    Property<block_dim_x_decode_retina_t> m_block_dim_x_decode_retina {this, 256};
  };
} // namespace decode_retinaclusters
