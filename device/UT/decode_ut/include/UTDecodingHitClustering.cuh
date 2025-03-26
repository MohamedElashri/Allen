/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "UTRaw.cuh"
#include <MEPTools.h>
#include "UTDecoder.cuh"

namespace ut_decoding_hit_clustering {
  struct Parameters {
    // Basics
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Rawbank
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    // Hit offsets
    HOST_INPUT(host_total_number_of_ut_hits_t, unsigned) host_total_number_of_ut_hits;
    // Predecoding
    DEVICE_INPUT(dev_ut_predecoded_hits_t, uint32_t) dev_ut_predecoded_hits;
    DEVICE_INPUT(dev_ut_hits_strip_info_t, uint32_t) dev_ut_hits_strip_info;
    DEVICE_INPUT(dev_ut_predecoded_event_offsets_t, unsigned) dev_ut_predecoded_event_offsets;
    // Temporally output
    DEVICE_OUTPUT(dev_ut_hits_clustering_end_mask_t, unsigned) dev_ut_hits_clustering_end_mask;
    DEVICE_OUTPUT(dev_ut_hits_clustering_hit_offsets_t, unsigned) dev_ut_hits_clustering_hit_offsets;
    DEVICE_OUTPUT(dev_ut_all_clusters_t, uint64_t) dev_ut_all_clusters;
    DEVICE_OUTPUT(dev_ut_cluster_keys_t, uint64_t) dev_ut_cluster_keys;
    // Output
    HOST_OUTPUT(host_ut_num_clusters_t, unsigned) host_ut_num_clusters;
    DEVICE_OUTPUT(dev_ut_clusters_t, uint64_t) dev_ut_clusters;
    DEVICE_OUTPUT(dev_ut_clusters_sector_group_offsets_t, unsigned) dev_ut_clusters_sector_group_offsets;
    DEVICE_OUTPUT(dev_ut_clusters_permutations_t, unsigned) dev_ut_clusters_permutations;
  };

  struct ut_decoding_hit_clustering_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants& constants)
      const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<int> m_position_method {this, "position_method", 0, "weighting method for UT cluster position"};
    Allen::Property<unsigned> m_max_cluster_size {this, "max_cluster_size", 128u, "max size of UT clusters"};
    Allen::Property<bool> m_cluster_ut_hits {this, "cluster_ut_hits", true, "whether to cluster UT hits"};
    Allen::Property<bool> m_save_clusters_above_max {this,
                                                     "save_clusters_above_max",
                                                     true,
                                                     "whether to save UT clusters above max size"};
  };

  template<unsigned N>
  __global__ void ut_decoding_clustering_fill_mask(Parameters parameters, unsigned size);

  template<unsigned N>
  __global__ void ut_decoding_clustering_make_hit_offsets(Parameters parameters, unsigned size);

  __global__ void ut_decoding_clustering(
    Parameters parameters,
    const uint8_t* board_to_sector_group_map,
    bool save_clusters_above_max,
    unsigned max_cluster_size,
    int position_method);

  template<unsigned version>
  __global__ void ut_decoding_consolidate_clusters(
    Parameters parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const uint8_t* board_to_sector_group_map,
    const uint16_t* board_to_geometry_map);

  __global__ void ut_decoding_no_clustering_fill_offsets(
    Parameters parameters,
    const uint8_t* board_to_sector_group_map);

  template<unsigned version>
  __global__ void ut_decoding_no_clustering_fill(
    Parameters parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const uint8_t* board_to_sector_group_map,
    const uint16_t* board_to_geometry_map);

} // namespace ut_decoding_hit_clustering
