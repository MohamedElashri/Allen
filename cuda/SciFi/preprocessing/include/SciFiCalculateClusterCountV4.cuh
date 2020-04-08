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
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void scifi_calculate_cluster_count_v4(Parameters, const char* scifi_geometry);

  __global__ void scifi_calculate_cluster_count_v4_mep(Parameters, const char* scifi_geometry);

  template<typename T, char... S>
  struct scifi_calculate_cluster_count_v4_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(scifi_calculate_cluster_count_v4)) function {scifi_calculate_cluster_count_v4};
    decltype(global_function(scifi_calculate_cluster_count_v4_mep)) function_mep {scifi_calculate_cluster_count_v4_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_scifi_raw_input_t>(arguments, std::get<1>(runtime_options.host_scifi_events));
      set_size<dev_scifi_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_scifi_events).size_bytes() / sizeof(uint32_t));
      set_size<dev_scifi_hit_count_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * SciFi::Constants::n_mat_groups_and_mats);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      data_to_device<dev_scifi_raw_input_t, dev_scifi_raw_input_offsets_t>
        (arguments, runtime_options.host_scifi_events, cuda_stream);

      initialize<dev_scifi_hit_count_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters {begin<dev_scifi_raw_input_t>(arguments),
                                          begin<dev_scifi_raw_input_offsets_t>(arguments),
                                          begin<dev_scifi_hit_count_t>(arguments),
                                          begin<dev_event_list_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
      }
      else {
        function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{240, 1, 1}}};
  };
} // namespace scifi_calculate_cluster_count_v4
