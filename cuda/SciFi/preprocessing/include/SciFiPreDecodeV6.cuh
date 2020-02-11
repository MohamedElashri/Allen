#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

__device__ void store_sorted_cluster_reference_v6(
  SciFi::ConstHitCount& hit_count,
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

namespace scifi_pre_decode_v6 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_scifi_hits_t, uint);
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, uint) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_OUTPUT(dev_scifi_hits_t, char) dev_scifi_hits;
  };

  __global__ void scifi_pre_decode_v6(Parameters, const char* scifi_geometry);

  template<typename T, char... S>
  struct scifi_pre_decode_v6_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(scifi_pre_decode_v6)) function {scifi_pre_decode_v6};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_scifi_hits_t>(
        arguments,
        value<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::hits_number_of_arrays * sizeof(uint32_t));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(
        dim3(value<host_number_of_selected_events_t>(arguments)),
        dim3(SciFi::SciFiRawBankParams::NbBanks),
        cuda_stream)(
        Parameters {begin<dev_scifi_raw_input_t>(arguments),
                    begin<dev_scifi_raw_input_offsets_t>(arguments),
                    begin<dev_event_list_t>(arguments),
                    begin<dev_scifi_hit_count_t>(arguments),
                    begin<dev_scifi_hits_t>(arguments)},
        constants.dev_scifi_geometry);
    }
  };
} // namespace scifi_pre_decode_v6