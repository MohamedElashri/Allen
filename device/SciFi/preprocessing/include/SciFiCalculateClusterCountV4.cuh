#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_calculate_cluster_count_v4 {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_INPUT(dev_scifi_raw_input_t, char), dev_scifi_raw_input),
    (DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint), dev_scifi_raw_input_offsets),
    (DEVICE_OUTPUT(dev_scifi_hit_count_t, uint), dev_scifi_hit_count),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void scifi_calculate_cluster_count_v4(Parameters, const char* scifi_geometry);

  __global__ void scifi_calculate_cluster_count_v4_mep(Parameters, const char* scifi_geometry);

  struct scifi_calculate_cluster_count_v4_t : public DeviceAlgorithm, Parameters {
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

  private:
    Property<block_dim_t> m_block_dim {this, {{240, 1, 1}}};
  };
} // namespace scifi_calculate_cluster_count_v4
