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
#include "UTRaw.cuh"

namespace ut_decode_in_order {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_ut_clusters_t, unsigned) host_accumulated_number_of_ut_clusters;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ut_pre_decoded_hits_t, char) dev_ut_pre_decoded_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_ut_permutations_t, unsigned) dev_ut_permutations;
    DEVICE_INPUT(dev_ut_clustering_offsets_t, unsigned) dev_ut_clustering_offsets;
    DEVICE_OUTPUT(dev_ut_hits_t, char) dev_ut_hits;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  /**
   * @brief Fully decodes pre-decoding information into geometry for tracking, storing fully decoded UT hits it in a
   * sorted manner.
   */
  __global__ void ut_decode_in_order(
    Parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const unsigned* dev_unique_x_sector_layer_offsets);

  struct ut_decode_in_order_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };
} // namespace ut_decode_in_order
