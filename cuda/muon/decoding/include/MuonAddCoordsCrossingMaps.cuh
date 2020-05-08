#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

namespace muon_add_coords_crossing_maps {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_muon_total_number_of_tiles_t, uint);
    DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, uint) dev_storage_station_region_quarter_offsets;
    DEVICE_INPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits) dev_muon_raw_to_hits;
    DEVICE_OUTPUT(dev_atomics_index_insert_t, uint) dev_atomics_index_insert;
    DEVICE_OUTPUT(dev_muon_compact_hit_t, uint64_t) dev_muon_compact_hit;
    DEVICE_OUTPUT(dev_muon_tile_used_t, bool) dev_muon_tile_used;
    DEVICE_OUTPUT(dev_station_ocurrences_sizes_t, uint) dev_station_ocurrences_sizes;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void muon_add_coords_crossing_maps(Parameters);

  template<typename T, char... S>
  struct muon_add_coords_crossing_maps_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(muon_add_coords_crossing_maps)) function {muon_add_coords_crossing_maps};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_muon_compact_hit_t>(
        arguments, value<host_muon_total_number_of_tiles_t>(arguments));
      set_size<dev_muon_tile_used_t>(
        arguments, value<host_muon_total_number_of_tiles_t>(arguments));
      set_size<dev_station_ocurrences_sizes_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Muon::Constants::n_stations);
      set_size<dev_atomics_index_insert_t>(
        arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_muon_compact_hit_t>(arguments, 0, cuda_stream);
      initialize<dev_muon_tile_used_t>(arguments, 0, cuda_stream);
      initialize<dev_station_ocurrences_sizes_t>(arguments, 0, cuda_stream);
      initialize<dev_atomics_index_insert_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_storage_station_region_quarter_offsets_t>(arguments),
                    begin<dev_storage_tile_id_t>(arguments),
                    begin<dev_muon_raw_to_hits_t>(arguments),
                    begin<dev_atomics_index_insert_t>(arguments),
                    begin<dev_muon_compact_hit_t>(arguments),
                    begin<dev_muon_tile_used_t>(arguments),
                    begin<dev_station_ocurrences_sizes_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace muon_add_coords_crossing_maps