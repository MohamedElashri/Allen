#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

namespace muon_pre_decoding {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_muon_raw_t, char) dev_muon_raw;
    DEVICE_OUTPUT(dev_muon_raw_offsets_t, uint) dev_muon_raw_offsets;
    DEVICE_OUTPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits) dev_muon_raw_to_hits;
    DEVICE_OUTPUT(dev_storage_station_region_quarter_sizes_t, uint) dev_storage_station_region_quarter_offsets;
    DEVICE_OUTPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_OUTPUT(dev_storage_tdc_value_t, uint) dev_storage_tdc_value;
    DEVICE_OUTPUT(dev_atomics_muon_t, uint) dev_atomics_muon;
  };

  __global__ void muon_pre_decoding(Parameters);

  __global__ void muon_pre_decoding_mep(Parameters);

  template<typename T, char... S>
  struct muon_pre_decoding_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(muon_pre_decoding)) function {muon_pre_decoding};
    decltype(global_function(muon_pre_decoding_mep)) function_mep {muon_pre_decoding_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_muon_raw_t>(arguments, std::get<1>(runtime_options.host_muon_events));
      set_size<dev_muon_raw_offsets_t>(
        arguments, std::get<2>(runtime_options.host_muon_events).size_bytes() / sizeof(uint32_t));
      set_size<dev_muon_raw_to_hits_t>(arguments, 1);
      set_size<dev_storage_station_region_quarter_sizes_t>(
        arguments,
        value<host_number_of_selected_events_t>(arguments) * Muon::Constants::n_stations * Muon::Constants::n_regions *
            Muon::Constants::n_quarters +
          1);
      set_size<dev_storage_tile_id_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Muon::Constants::max_numhits_per_event);
      set_size<dev_storage_tdc_value_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Muon::Constants::max_numhits_per_event);
      set_size<dev_atomics_muon_t>(arguments, 2 * value<host_number_of_selected_events_t>(arguments));
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

      initialize<dev_storage_station_region_quarter_sizes_t>(arguments, 0, cuda_stream);

      initialize<dev_atomics_muon_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters {begin<dev_event_list_t>(arguments),
                                          begin<dev_muon_raw_t>(arguments),
                                          begin<dev_muon_raw_offsets_t>(arguments),
                                          begin<dev_muon_raw_to_hits_t>(arguments),
                                          begin<dev_storage_station_region_quarter_sizes_t>(arguments),
                                          begin<dev_storage_tile_id_t>(arguments),
                                          begin<dev_storage_tdc_value_t>(arguments),
                                          begin<dev_atomics_muon_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(
          value<host_number_of_selected_events_t>(arguments),
          Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank,
          cuda_stream)(parameters);
      }
      else {
        function(
          value<host_number_of_selected_events_t>(arguments),
          Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank,
          cuda_stream)(parameters);
      }
    }
  };
} // namespace muon_pre_decoding
