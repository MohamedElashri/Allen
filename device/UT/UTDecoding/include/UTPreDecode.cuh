/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTEventModel.cuh"

namespace ut_pre_decode {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned), host_accumulated_number_of_ut_hits),
    (DEVICE_INPUT(dev_ut_raw_input_t, char), dev_ut_raw_input),
    (DEVICE_INPUT(dev_ut_raw_input_offsets_t, unsigned), dev_ut_raw_input_offsets),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned), dev_ut_hit_offsets),
    (DEVICE_OUTPUT(dev_ut_pre_decoded_hits_t, char), dev_ut_pre_decoded_hits),
    (DEVICE_OUTPUT(dev_ut_hit_count_t, unsigned), dev_ut_hit_count),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void ut_pre_decode(
    Parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const unsigned* dev_ut_region_offsets,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const unsigned* dev_unique_x_sector_offsets);

  __global__ void ut_pre_decode_mep(
    Parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const unsigned* dev_ut_region_offsets,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const unsigned* dev_unique_x_sector_offsets);

  struct ut_pre_decode_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 4, 1}}};
  };
} // namespace ut_pre_decode
