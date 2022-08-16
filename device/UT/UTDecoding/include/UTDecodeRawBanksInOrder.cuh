/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "UTEventModel.cuh"
#include "UTRaw.cuh"

namespace ut_decode_raw_banks_in_order {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, unsigned) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_ut_raw_input_sizes_t, unsigned) dev_ut_raw_input_sizes;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_ut_pre_decoded_hits_t, char) dev_ut_pre_decoded_hits;
    DEVICE_OUTPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_permutations_t, unsigned) dev_ut_hit_permutations;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  template<int decoding_version, bool mep>
  __global__ void ut_decode_raw_banks_in_order(
    Parameters,
    const unsigned event_start,
    const char* ut_boards,
    const char* ut_geometry,
    const unsigned* dev_ut_region_offsets,
    const unsigned* dev_unique_x_sector_layer_offsets);

  struct ut_decode_raw_banks_in_order_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };
} // namespace ut_decode_raw_banks_in_order
