#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_raw_bank_decoder_v5 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_scifi_hits_t, uint);
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_OUTPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void scifi_raw_bank_decoder_v5(
    Parameters,
    const char* scifi_geometry);

  template<typename T, char... S>
  struct scifi_raw_bank_decoder_v5_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(scifi_raw_bank_decoder_v5)) function {scifi_raw_bank_decoder_v5};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      const auto dev_scifi_hits_size =
        value<host_accumulated_number_of_scifi_hits_t>(arguments) * sizeof(SciFi::Hit) / sizeof(uint);
      set_size<dev_scifi_hits_t>(arguments, dev_scifi_hits_size);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<blockdim_t>(), cuda_stream)(
        Parameters {begin<dev_scifi_raw_input_t>(arguments),
                    begin<dev_scifi_raw_input_offsets_t>(arguments),
                    begin<dev_event_list_t>(arguments),
                    begin<dev_scifi_hit_count_t>(arguments),
                    begin<dev_scifi_hits_t>(arguments)},
        constants.dev_scifi_geometry);
    }

  private:
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace scifi_raw_bank_decoder_v5