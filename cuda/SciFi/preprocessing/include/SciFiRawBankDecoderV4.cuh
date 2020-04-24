#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_raw_bank_decoder_v4 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_scifi_hits_t, uint);
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_cluster_references_t, uint) dev_cluster_references;
    DEVICE_OUTPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    PROPERTY(raw_bank_decoder_block_dim_t, DeviceDimensions, "raw_bank_decoder_block_dim", "block dimensions of raw bank decoder kernel");
    PROPERTY(direct_decoder_block_dim_t, DeviceDimensions, "direct_decoder_block_dim", "block dimensions of direct decoder");
  };

  __global__ void scifi_raw_bank_decoder_v4(Parameters, const char* scifi_geometry);

  __global__ void scifi_direct_decoder_v4(Parameters, const char* scifi_geometry);

  __global__ void scifi_raw_bank_decoder_v4_mep(Parameters, const char* scifi_geometry);

  __global__ void scifi_direct_decoder_v4_mep(Parameters, const char* scifi_geometry);

  template<typename T, char... S>
  struct scifi_raw_bank_decoder_v4_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(scifi_raw_bank_decoder_v4)) raw_bank_decoder {scifi_raw_bank_decoder_v4};
    decltype(global_function(scifi_direct_decoder_v4)) direct_decoder {scifi_direct_decoder_v4};
    decltype(global_function(scifi_raw_bank_decoder_v4_mep)) raw_bank_decoder_mep {scifi_raw_bank_decoder_v4_mep};
    decltype(global_function(scifi_direct_decoder_v4_mep)) direct_decoder_mep {scifi_direct_decoder_v4_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_scifi_hits_t>(
        arguments,
        value<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays * sizeof(uint32_t));
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
                                          begin<dev_scifi_hit_offsets_t>(arguments),
                                          begin<dev_cluster_references_t>(arguments),
                                          begin<dev_scifi_hits_t>(arguments),
                                          begin<dev_event_list_t>(arguments)};

      if (runtime_options.mep_layout) {
        raw_bank_decoder_mep(dim3(value<host_number_of_selected_events_t>(arguments)), property<raw_bank_decoder_block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
        direct_decoder_mep(dim3(value<host_number_of_selected_events_t>(arguments)), property<direct_decoder_block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
      }
      else {
        raw_bank_decoder(dim3(value<host_number_of_selected_events_t>(arguments)), property<raw_bank_decoder_block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
        direct_decoder(dim3(value<host_number_of_selected_events_t>(arguments)), property<direct_decoder_block_dim_t>(), cuda_stream)(
          parameters, constants.dev_scifi_geometry);
      }
    }

  private:
    Property<raw_bank_decoder_block_dim_t> m_raw_bank_decoder_block_dim {this, {{256, 1, 1}}};
    Property<direct_decoder_block_dim_t> m_direct_decoder_block_dim {this, {{2, 16, 1}}};
  };
} // namespace scifi_raw_bank_decoder_v4
