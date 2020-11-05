/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_calculate_cluster_count_v6 {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, unsigned) dev_scifi_raw_input_offsets;
    DEVICE_OUTPUT(dev_scifi_hit_count_t, unsigned) dev_scifi_hit_count;
  };

  __global__ void scifi_calculate_cluster_count_v6(Parameters, const char* scifi_geometry);

  __global__ void scifi_calculate_cluster_count_v6_mep(Parameters, const char* scifi_geometry);

  struct scifi_calculate_cluster_count_v6_t : public DeviceAlgorithm, Parameters {
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
  };
} // namespace scifi_calculate_cluster_count_v6
