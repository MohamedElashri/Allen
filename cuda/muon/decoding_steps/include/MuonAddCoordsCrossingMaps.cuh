#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

namespace muon_add_coords_crossing_maps {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, uint) dev_storage_station_region_quarter_offsets;
    DEVICE_OUTPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_OUTPUT(dev_storage_tdc_value_t, uint) dev_storage_tdc_value;
    DEVICE_OUTPUT(dev_atomics_muon_t, uint) dev_atomics_muon;
    DEVICE_OUTPUT(dev_muon_hits_t, uint) dev_muon_hits;
    DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits) dev_muon_raw_to_hits;
    DEVICE_OUTPUT(dev_station_ocurrences_offset_t, uint) dev_station_ocurrences_offset;
    DEVICE_OUTPUT(dev_muon_compact_hit_t, uint) dev_muon_compact_hit;
  };

  __global__ void muon_add_coords_crossing_maps(Parameters);

  template<typename T>
  struct muon_add_coords_crossing_maps_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"muon_add_coords_crossing_maps_t"};
    decltype(global_function(muon_add_coords_crossing_maps)) function {muon_add_coords_crossing_maps};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_muon_hits_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_station_ocurrences_offset_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Muon::Constants::n_stations);
      set_size<dev_muon_compact_hit_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Muon::Constants::max_numhits_per_event);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemsetAsync(
        offset<dev_station_ocurrences_offset_t>(arguments),
        0,
        size<dev_station_ocurrences_offset_t>(arguments),
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        offset<dev_muon_compact_hit_t>(arguments), 0, size<dev_muon_compact_hit_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_storage_station_region_quarter_offsets_t>(arguments),
                    offset<dev_storage_tile_id_t>(arguments),
                    offset<dev_storage_tdc_value_t>(arguments),
                    offset<dev_atomics_muon_t>(arguments),
                    offset<dev_muon_raw_to_hits_t>(arguments),
                    offset<dev_muon_compact_hit_t>(arguments),
                    offset<dev_station_ocurrences_offset_t>(arguments)});
    }
  };
} // namespace muon_add_coords_crossing_maps