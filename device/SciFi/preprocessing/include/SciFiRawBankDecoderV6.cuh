/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_raw_bank_decoder_v6 {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_accumulated_number_of_scifi_hits_t, unsigned), host_accumulated_number_of_scifi_hits),
    (DEVICE_INPUT(dev_scifi_raw_input_t, char), dev_scifi_raw_input),
    (DEVICE_INPUT(dev_scifi_raw_input_offsets_t, unsigned), dev_scifi_raw_input_offsets),
    (DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned), dev_scifi_hit_offsets),
    (DEVICE_INPUT(dev_cluster_references_t, unsigned), dev_cluster_references),
    (DEVICE_OUTPUT(dev_scifi_hits_t, char), dev_scifi_hits),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void scifi_raw_bank_decoder_v6(Parameters, const char* scifi_geometry);

  __global__ void scifi_raw_bank_decoder_v6_mep(Parameters, const char* scifi_geometry);

  struct scifi_raw_bank_decoder_v6_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace scifi_raw_bank_decoder_v6