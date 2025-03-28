/*****************************************************************************\
* (c) Copyright 2018-2024 CERN for the benefit of the LHCb Collaboration      *
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

namespace velo_sparse_ccl {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    HOST_INPUT(host_total_number_of_superpixels_t, unsigned) host_total_number_of_superpixels;
    DEVICE_INPUT(dev_superpixels_t, unsigned) dev_superpixels;
    DEVICE_INPUT(dev_superpixels_offsets_t, unsigned) dev_superpixels_offsets;

    DEVICE_OUTPUT(dev_labels_t, unsigned) dev_labels;
    DEVICE_OUTPUT(dev_pixels_features_t, uint64_t) dev_pixels_features;

    DEVICE_OUTPUT(dev_module_pair_cluster_num_t, unsigned) dev_module_pair_cluster_num;
    DEVICE_OUTPUT(dev_module_pair_cluster_offset_t, unsigned) dev_module_pair_cluster_offset;
    HOST_OUTPUT(host_total_number_of_clusters_t, unsigned) host_total_number_of_clusters;
    DEVICE_OUTPUT(dev_velo_cluster_container_t, char) dev_velo_cluster_container;

    DEVICE_OUTPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_OUTPUT(dev_hit_permutation_t, unsigned) dev_hit_permutation;
    DEVICE_OUTPUT(dev_hit_sorting_key_t, int64_t) dev_hit_sorting_key;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_clusters_t,
      DEPENDENCIES(dev_velo_cluster_container_t, dev_module_pair_cluster_num_t, dev_number_of_events_t),
      Velo::Clusters)
    dev_velo_clusters;
  };

  struct velo_sparse_ccl_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;
  };
} // namespace velo_sparse_ccl
