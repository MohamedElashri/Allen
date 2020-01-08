#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace scifi_pre_decode_v4 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_OUTPUT(dev_scifi_hits_t, uint) dev_scifi_hits;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
  };

  __device__ void store_sorted_cluster_reference_v4(
    const SciFi::HitCount& hit_count,
    const uint32_t uniqueMat,
    const uint32_t chan,
    const uint32_t* shared_mat_offsets,
    uint32_t* shared_mat_count,
    const int raw_bank,
    const int it,
    const int condition_1,
    const int condition_2,
    const int delta,
    SciFi::Hits& hits);

  __global__ void scifi_pre_decode_v4(
    Parameters,
    char* scifi_geometry,
    const float* dev_inv_clus_res);

  template<typename T>
  struct scifi_pre_decode_v4_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"scifi_pre_decode_v4_t"};
    decltype(global_function(scifi_pre_decode_v4)) function {scifi_pre_decode_v4};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      arguments.set_size<dev_scifi_hits>(host_buffers.scifi_hits_uints());
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(
        dim3(value<host_number_of_selected_events_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), cuda_stream)(
        Parameters {arguments.offset<dev_scifi_raw_input_t>(),
                    arguments.offset<dev_scifi_raw_input_offsets_t>(),
                    arguments.offset<dev_scifi_hit_count_t>(),
                    arguments.offset<dev_scifi_hits_t>(),
                    arguments.offset<dev_event_list_t>()},
        constants.dev_scifi_geometry,
        constants.dev_inv_clus_res);
    }
  };
} // namespace scifi_pre_decode_v4