#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_raw_bank_decoder_v6 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_scifi_hits_t, uint);
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, uint) dev_scifi_hit_offsets;
    DEVICE_INPUT(dev_cluster_references_t, uint) dev_cluster_references;
    DEVICE_OUTPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };

  __global__ void scifi_raw_bank_decoder_v6(Parameters, const char* scifi_geometry);

  __global__ void scifi_raw_bank_decoder_v6_mep(Parameters, const char* scifi_geometry);

  template<typename T>
  struct scifi_raw_bank_decoder_v6_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(scifi_raw_bank_decoder_v6)) function {scifi_raw_bank_decoder_v6};
    decltype(global_function(scifi_raw_bank_decoder_v6_mep)) function_mep {scifi_raw_bank_decoder_v6_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_scifi_hits_t>(
        arguments,
        first<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays * sizeof(uint32_t));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      const auto parameters = Parameters {data<dev_scifi_raw_input_t>(arguments),
                                          data<dev_scifi_raw_input_offsets_t>(arguments),
                                          data<dev_scifi_hit_offsets_t>(arguments),
                                          data<dev_cluster_references_t>(arguments),
                                          data<dev_scifi_hits_t>(arguments),
                                          data<dev_event_list_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
      }
      else {
        function(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace scifi_raw_bank_decoder_v6