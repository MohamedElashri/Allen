#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_calculate_cluster_count_v4 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_OUTPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void scifi_calculate_cluster_count_v4(Parameters, const char* scifi_geometry);

  __global__ void scifi_calculate_cluster_count_v4_mep(Parameters, const char* scifi_geometry);

  template<typename T>
  struct scifi_calculate_cluster_count_v4_t : public DeviceAlgorithm, Parameters {


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

      using function_t = decltype(global_function(scifi_calculate_cluster_count_v4));
      function_t function = runtime_options.mep_layout ? function_t{scifi_calculate_cluster_count_v4_mep} : function_t{scifi_calculate_cluster_count_v4};
      function(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        parameters, constants.dev_scifi_geometry);
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{240, 1, 1}}};
  };
} // namespace scifi_calculate_cluster_count_v4
