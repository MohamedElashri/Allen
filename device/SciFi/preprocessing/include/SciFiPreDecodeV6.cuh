#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_pre_decode_v6 {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (HOST_INPUT(host_accumulated_number_of_scifi_hits_t, uint), host_accumulated_number_of_scifi_hits),
    (DEVICE_INPUT(dev_scifi_raw_input_t, char), dev_scifi_raw_input),
    (DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint), dev_scifi_raw_input_offsets),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_INPUT(dev_scifi_hit_offsets_t, uint), dev_scifi_hit_offsets),
    (DEVICE_OUTPUT(dev_cluster_references_t, uint), dev_cluster_references))

  __global__ void scifi_pre_decode_v6(Parameters, const char* scifi_geometry);

  __global__ void scifi_pre_decode_v6_mep(Parameters, const char* scifi_geometry);

  struct scifi_pre_decode_v6_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;
  };
} // namespace scifi_pre_decode_v6