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
#include "UTEventModel.cuh"

namespace ut_decoding_decode_clusters {
  struct Parameters {
    // Basics
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Rawbank
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    // Clustering
    HOST_INPUT(host_ut_num_clusters_t, unsigned) host_ut_num_clusters;
    DEVICE_INPUT(dev_ut_clusters_t, uint64_t) dev_ut_clusters;
    DEVICE_INPUT(dev_ut_clusters_sector_group_offsets_t, unsigned) dev_ut_clusters_sector_group_offsets;
    DEVICE_INPUT(dev_ut_clusters_permutations_t, unsigned) dev_ut_clusters_permutations;
    // Output
    DEVICE_OUTPUT(dev_ut_hits_t, char) dev_ut_hits;
  };

  struct ut_decoding_decode_clusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants& constants)
      const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
  };

  template<unsigned N, unsigned version>
  __global__ void ut_decoding_decode_clusters(
    Parameters parameters,
    const unsigned total_number_of_clusters,
    const char* ut_boards,
    const char* ut_geometry,
    const uint8_t* board_to_sector_group_map,
    const uint16_t* board_to_geometry_map);
} // namespace ut_decoding_decode_clusters
