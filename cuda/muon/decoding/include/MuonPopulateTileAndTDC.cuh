#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

namespace muon_populate_tile_and_tdc {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_muon_total_number_of_tiles_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_muon_raw_t, char) dev_muon_raw;
    DEVICE_INPUT(dev_muon_raw_offsets_t, uint) dev_muon_raw_offsets;
    DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits) dev_muon_raw_to_hits;
    DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, uint) dev_storage_station_region_quarter_offsets;
    DEVICE_OUTPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_OUTPUT(dev_storage_tdc_value_t, uint) dev_storage_tdc_value;
    DEVICE_OUTPUT(dev_atomics_muon_t, uint) dev_atomics_muon;
  };

  __global__ void muon_populate_tile_and_tdc(Parameters);

  __global__ void muon_populate_tile_and_tdc_mep(Parameters);

  template<typename T, char... S>
  struct muon_populate_tile_and_tdc_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_storage_tile_id_t>(
        arguments, value<host_muon_total_number_of_tiles_t>(arguments));
      set_size<dev_storage_tdc_value_t>(
        arguments, value<host_muon_total_number_of_tiles_t>(arguments));
      set_size<dev_atomics_muon_t>(arguments,
        value<host_number_of_selected_events_t>(arguments) * Muon::Constants::n_stations * Muon::Constants::n_regions *
            Muon::Constants::n_quarters);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_atomics_muon_t>(arguments, 0, cuda_stream);
      initialize<dev_storage_tile_id_t>(arguments, 0, cuda_stream);
      initialize<dev_storage_tdc_value_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters {begin<dev_event_list_t>(arguments),
                                          begin<dev_muon_raw_t>(arguments),
                                          begin<dev_muon_raw_offsets_t>(arguments),
                                          begin<dev_muon_raw_to_hits_t>(arguments),
                                          begin<dev_storage_station_region_quarter_offsets_t>(arguments),
                                          begin<dev_storage_tile_id_t>(arguments),
                                          begin<dev_storage_tdc_value_t>(arguments),
                                          begin<dev_atomics_muon_t>(arguments)};

      using function_t = decltype(global_function(muon_populate_tile_and_tdc));
      function_t function = runtime_options.mep_layout ? function_t {muon_populate_tile_and_tdc_mep} : function_t {muon_populate_tile_and_tdc};
      function(value<host_number_of_selected_events_t>(arguments),
        Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank,
        cuda_stream)(parameters);
    }
  };
} // namespace muon_populate_tile_and_tdc
