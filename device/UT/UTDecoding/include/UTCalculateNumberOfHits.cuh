/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_calculate_number_of_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, unsigned) dev_ut_raw_input_offsets;
    DEVICE_OUTPUT(dev_ut_hit_sizes_t, unsigned) dev_ut_hit_sizes;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
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

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 4, 1}}};
  };

  template<int decoding_version, bool mep>
  __global__ void ut_calculate_number_of_hits(
    Parameters,
    const char* ut_boards,
    const unsigned* dev_ut_region_offsets,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const unsigned* dev_unique_x_sector_offsets);

} // namespace ut_calculate_number_of_hits
