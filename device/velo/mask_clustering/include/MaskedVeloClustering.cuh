/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <cassert>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "VeloTools.cuh"

namespace velo_masked_clustering {
  struct Parameters {
    HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned) host_total_number_of_velo_clusters;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    DEVICE_INPUT(dev_superpixels_t, unsigned) dev_superpixels;
    DEVICE_INPUT(dev_superpixels_offsets_t, unsigned) dev_superpixels_offsets;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_candidate_num_t, unsigned) dev_module_pair_candidate_num;
    DEVICE_INPUT(dev_cluster_candidates_t, unsigned) dev_cluster_candidates;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_candidates_offsets_t, unsigned) dev_candidates_offsets;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_velo_bank_index_t, unsigned) dev_velo_bank_index;
    DEVICE_OUTPUT(dev_module_cluster_num_t, unsigned) dev_module_pair_cluster_num;
    DEVICE_OUTPUT(dev_velo_cluster_container_t, char) dev_velo_cluster_container;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_clusters_t,
      DEPENDENCIES(dev_velo_cluster_container_t, dev_module_cluster_num_t, dev_number_of_events_t),
      Velo::Clusters)
    dev_velo_clusters;
  };

  struct velo_masked_clustering_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };
} // namespace velo_masked_clustering
