#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_calculate_cluster_count_v6 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_OUTPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
  };

  __global__ void scifi_calculate_cluster_count_v6(Parameters, char* scifi_geometry);

  template<typename T, char... S>
  struct scifi_calculate_cluster_count_v6_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(scifi_calculate_cluster_count_v6)) function {scifi_calculate_cluster_count_v6};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_scifi_hit_count_t>(
        arguments, 2 * value<host_number_of_selected_events_t>(arguments) * SciFi::Constants::n_mats);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemsetAsync(
        begin<dev_scifi_hit_count_t>(arguments), 0, size<dev_scifi_hit_count_t>(arguments), cuda_stream));

      function(
        dim3(value<host_number_of_selected_events_t>(arguments)),
        dim3(SciFi::SciFiRawBankParams::NbBanks),
        cuda_stream)(
        Parameters {begin<dev_scifi_raw_input_t>(arguments),
                    begin<dev_scifi_raw_input_offsets_t>(arguments),
                    begin<dev_event_list_t>(arguments),
                    begin<dev_scifi_hit_count_t>(arguments)},
        constants.dev_scifi_geometry);
    }
  };
} // namespace scifi_calculate_cluster_count_v6