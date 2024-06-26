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

#include "AlgorithmTypes.cuh"
#include <RichDefinitions.cuh>

namespace rich_decoding {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, uint) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_rich_raw_input_t, char) dev_rich_raw_input;
    DEVICE_INPUT(dev_rich_raw_input_offsets_t, uint) dev_rich_raw_input_offsets;
    DEVICE_INPUT(dev_rich_raw_input_sizes_t, uint) dev_rich_raw_input_sizes;
    DEVICE_INPUT(dev_rich_raw_input_types_t, uint) dev_rich_raw_input_types;
    DEVICE_OUTPUT(dev_rich_hit_offsets_t, unsigned) dev_rich_hit_offsets;
    HOST_OUTPUT(host_rich_total_number_of_hits_t, unsigned) host_rich_total_number_of_hits;
    DEVICE_OUTPUT(dev_smart_ids_t, Allen::RichSmartID) dev_smart_ids;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned) block_dim_x;
  };

  struct rich_decoding_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 64};
  };
} // namespace rich_decoding
