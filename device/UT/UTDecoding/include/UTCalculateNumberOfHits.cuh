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
#include "UTRaw.cuh"

namespace ut_calculate_number_of_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, unsigned) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_ut_raw_input_sizes_t, unsigned) dev_ut_raw_input_sizes;
    DEVICE_INPUT(dev_ut_raw_input_types_t, unsigned) dev_ut_raw_input_types;
    DEVICE_OUTPUT(dev_ut_nonempty_channels_t, uint16_t) dev_ut_nonempty_channels;
    DEVICE_OUTPUT(dev_ut_number_of_nonempty_channels_t, uint16_t) dev_ut_number_of_nonempty_channels;
    DEVICE_OUTPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
  };

  struct version_checks : public Allen::contract::Precondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct ut_calculate_number_of_hits_t : public DeviceAlgorithm, Parameters {
    // Register contracts for this algorithm
    using contracts = std::tuple<version_checks>;

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

  /**
   * @brief Calculates the number of UT strips in the event so that we can allocate enough memory to store pre-decoding
   * information.
   */
  template<int decoding_version, bool mep>
  __global__ void ut_calculate_number_of_hits(
    Parameters,
    const unsigned event_start,
    const char* ut_boards,
    const unsigned* dev_ut_sector_to_group_map,
    const uint16_t* dev_ut_board_geometry_map);

} // namespace ut_calculate_number_of_hits
