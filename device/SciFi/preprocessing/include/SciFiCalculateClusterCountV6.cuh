#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_calculate_cluster_count_v6 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_OUTPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
  };

  __global__ void scifi_calculate_cluster_count_v6(Parameters, const char* scifi_geometry);

  __global__ void scifi_calculate_cluster_count_v6_mep(Parameters, const char* scifi_geometry);

  template<typename T>
  struct scifi_calculate_cluster_count_v6_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(scifi_calculate_cluster_count_v6)) function {scifi_calculate_cluster_count_v6};
    decltype(global_function(scifi_calculate_cluster_count_v6_mep)) function_mep {scifi_calculate_cluster_count_v6_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_scifi_hit_count_t>(
        arguments, first<host_number_of_selected_events_t>(arguments) * SciFi::Constants::n_mat_groups_and_mats);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_scifi_hit_count_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters {data<dev_event_list_t>(arguments),
                                          data<dev_scifi_raw_input_t>(arguments),
                                          data<dev_scifi_raw_input_offsets_t>(arguments),
                                          data<dev_scifi_hit_count_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(
          dim3(first<host_number_of_selected_events_t>(arguments)),
          dim3(SciFi::SciFiRawBankParams::NbBanks),
          cuda_stream)(parameters, constants.dev_scifi_geometry);
      }
      else {
        function(
          dim3(first<host_number_of_selected_events_t>(arguments)),
          dim3(SciFi::SciFiRawBankParams::NbBanks),
          cuda_stream)(parameters, constants.dev_scifi_geometry);
      }
    }
  };
} // namespace scifi_calculate_cluster_count_v6
