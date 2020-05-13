#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_pre_decode_v4 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_scifi_hits_t, uint);
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, uint) dev_scifi_hit_count;
    DEVICE_OUTPUT(dev_cluster_references_t, uint) dev_cluster_references;
  };

  __global__ void scifi_pre_decode_v4(Parameters, const char* scifi_geometry);

  __global__ void scifi_pre_decode_v4_mep(Parameters, const char* scifi_geometry);

  template<typename T>
  struct scifi_pre_decode_v4_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(scifi_pre_decode_v4)) function {scifi_pre_decode_v4};
    decltype(global_function(scifi_pre_decode_v4_mep)) function_mep {scifi_pre_decode_v4_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_cluster_references_t>(
        arguments,
        value<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      const auto parameters = Parameters {begin<dev_scifi_raw_input_t>(arguments),
                                          begin<dev_scifi_raw_input_offsets_t>(arguments),
                                          begin<dev_event_list_t>(arguments),
                                          begin<dev_scifi_hit_offsets_t>(arguments),
                                          begin<dev_cluster_references_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(
          dim3(value<host_number_of_selected_events_t>(arguments)),
          dim3(SciFi::SciFiRawBankParams::NbBanks),
          cuda_stream)(parameters, constants.dev_scifi_geometry);
      }
      else {
        function(
          dim3(value<host_number_of_selected_events_t>(arguments)),
          dim3(SciFi::SciFiRawBankParams::NbBanks),
          cuda_stream)(parameters, constants.dev_scifi_geometry);
      }
    }
  };
} // namespace scifi_pre_decode_v4
