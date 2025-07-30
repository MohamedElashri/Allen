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

#include "UTDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "UTEventModel.cuh"

namespace ut_compress_and_calculate_keys {
  struct Parameters {
    HOST_INPUT(host_accumulated_number_of_ut_clusters_t, unsigned) host_accumulated_number_of_ut_hits;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_ut_cluster_offsets_t, unsigned) dev_ut_cluster_offsets;
    DEVICE_INPUT(dev_ut_uncompressed_hits_t, char) dev_ut_uncompressed_hits;
    DEVICE_INPUT(dev_ut_tiebreak_t, uint32_t) dev_ut_tiebreak;
    DEVICE_OUTPUT(dev_ut_compressed_hits_t, char) dev_ut_compressed_hits;
    DEVICE_OUTPUT(dev_ut_sort_keys_t, uint64_t) dev_ut_sort_keys;
  };

  /**
   * @brief UT clusters are uncompressed, compress them to adapt to sorting algorithm.
   */
  __global__ void ut_compress_and_calculate_keys(Parameters, const char* ut_geometry);

  struct ut_compress_and_calculate_keys_t : public DeviceAlgorithm, Parameters {
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
} // namespace ut_compress_and_calculate_keys
