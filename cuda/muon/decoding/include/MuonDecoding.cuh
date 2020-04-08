#pragma once

#include "CudaCommon.h"
#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"

namespace muon_decoding {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_muon_raw_t, char) dev_muon_raw;
    DEVICE_OUTPUT(dev_muon_raw_offsets_t, uint) dev_muon_raw_offsets;
    DEVICE_OUTPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits) dev_muon_raw_to_hits;
    DEVICE_OUTPUT(dev_muon_hits_t, Muon::HitsSoA) dev_muon_hits;
  };

  __global__ void muon_decoding(Parameters);

  template<typename T, char... S>
  struct muon_decoding_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(muon_decoding)) function {muon_decoding};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_muon_raw_t>(arguments, std::get<1>(runtime_options.host_muon_events));
      set_size<dev_muon_raw_offsets_t>(arguments, std::get<2>(runtime_options.host_muon_events).size_bytes() / sizeof(uint32_t));
      set_size<dev_muon_raw_to_hits_t>(arguments, 1);
      set_size<dev_muon_hits_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      // FIXME: this should be done as part of the consumers, but
      // currently it cannot. This is because it is not possible to
      // indicate dependencies between Consumer and/or Producers.
      Muon::MuonRawToHits muonRawToHits {constants.dev_muon_tables, constants.dev_muon_geometry};

      cudaCheck(cudaMemcpyAsync(
        begin<dev_muon_raw_to_hits_t>(arguments),
        &muonRawToHits,
        sizeof(muonRawToHits),
        cudaMemcpyHostToDevice,
        cuda_stream));

      data_to_device<dev_muon_raw_t, dev_muon_raw_offsets_t>
        (arguments, runtime_options.host_muon_events, cuda_stream);

      function(
        dim3(value<host_number_of_selected_events_t>(arguments)),
        dim3(Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters),
        cuda_stream)(Parameters {begin<dev_event_list_t>(arguments),
                                 begin<dev_muon_raw_t>(arguments),
                                 begin<dev_muon_raw_offsets_t>(arguments),
                                 begin<dev_muon_raw_to_hits_t>(arguments),
                                 begin<dev_muon_hits_t>(arguments)});
    }
  };
} // namespace muon_decoding