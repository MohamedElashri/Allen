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

namespace ut_cluster_and_pre_decode {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, unsigned) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_ut_raw_input_sizes_t, unsigned) dev_ut_raw_input_sizes;
    DEVICE_INPUT(dev_ut_raw_input_types_t, unsigned) dev_ut_raw_input_types;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_ut_nonempty_channels_t, uint16_t) dev_ut_nonempty_channels;
    DEVICE_INPUT(dev_ut_number_of_nonempty_channels_t, uint16_t) dev_ut_number_of_nonempty_channels;
    DEVICE_OUTPUT(dev_ut_pre_decoded_hits_t, char) dev_ut_pre_decoded_hits;
    DEVICE_OUTPUT(dev_ut_tiebreak_t, uint32_t) dev_ut_tiebreak;
    DEVICE_OUTPUT(dev_ut_cluster_offsets_t, unsigned) dev_ut_cluster_offsets;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
  };

  /**
   * @brief UT raw banks are pre-decoded and clustered.
   *
   * @detail The minimum amount of information is stored on UTPreDecodedHits so that we don't have to read raw banks
   * again. Also, the number of UT clusters (dev_ut_cluster_offsets_t) is output and prefix summed later. This is
   * because number_of_ut_clusters < number_of_ut_hits, so we actually allocated more memory than needed for
   * pre-decoding. The full decoding will allocate the exact amount of memory needed.
   */
  template<int decoding_version, bool mep>
  __global__ void ut_cluster_and_pre_decode(
    Parameters,
    const unsigned event_start,
    const char* ut_boards,
    const char* ut_geometry,
    const unsigned* dev_ut_sector_to_group_map,
    const uint16_t* dev_ut_board_geometry_map,
    const bool cluster_ut_hits,
    const int position_method,
    const unsigned max_cluster_size,
    const bool save_clusters_above_max);

  struct ut_cluster_and_pre_decode_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants& constants)
      const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 4, 1}, "block dimensions"};
    Allen::Property<int> m_position_method {this, "position_method", 0, "weighting method for UT cluster position"};
    Allen::Property<unsigned> m_max_cluster_size {this, "max_cluster_size", 4u, "max size of UT clusters"};
    Allen::Property<bool> m_cluster_ut_hits {this, "cluster_ut_hits", true, "whether to cluster UT hits"};
    Allen::Property<bool> m_save_clusters_above_max {this,
                                                     "save_clusters_above_max",
                                                     true,
                                                     "whether to save UT clusters above max size"};
  };
} // namespace ut_cluster_and_pre_decode
