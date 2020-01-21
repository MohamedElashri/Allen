#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_calculate_cluster_count_v4 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_OUTPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_OUTPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
  };

  __global__ void scifi_calculate_cluster_count_v4(
    Parameters,
    const char* scifi_geometry);

  template<typename T, char... S>
  struct scifi_calculate_cluster_count_v4_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(scifi_calculate_cluster_count_v4)) function {scifi_calculate_cluster_count_v4};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_scifi_raw_input_t>(arguments, std::get<0>(runtime_options.host_scifi_events).size_bytes());
      set_size<dev_scifi_raw_input_offsets_t>(arguments, std::get<1>(runtime_options.host_scifi_events).size_bytes());
      set_size<dev_scifi_hit_count_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * SciFi::Constants::n_mat_groups_and_mats);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemcpyAsync(
        offset<dev_scifi_raw_input_t>(arguments),
        std::get<0>(runtime_options.host_scifi_events).begin(),
        std::get<0>(runtime_options.host_scifi_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        offset<dev_scifi_raw_input_offsets_t>(arguments),
        std::get<1>(runtime_options.host_scifi_events).begin(),
        std::get<1>(runtime_options.host_scifi_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        offset<dev_scifi_hit_count_t>(arguments), 0, size<dev_scifi_hit_count_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_scifi_raw_input_t>(arguments),
                    offset<dev_scifi_raw_input_offsets_t>(arguments),
                    offset<dev_scifi_hit_count_t>(arguments),
                    offset<dev_event_list_t>(arguments)},
        constants.dev_scifi_geometry);
    }
  };
} // namespace scifi_calculate_cluster_count_v4