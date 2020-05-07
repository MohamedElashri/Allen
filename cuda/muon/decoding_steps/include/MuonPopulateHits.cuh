#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "FindPermutation.cuh"
#include "MuonRawToHits.cuh"

namespace muon_populate_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_muon_total_number_of_hits_t, uint);
    DEVICE_INPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_INPUT(dev_storage_tdc_value_t, uint) dev_storage_tdc_value;
    DEVICE_OUTPUT(dev_permutation_station_t, uint) dev_permutation_station;
    DEVICE_OUTPUT(dev_muon_hits_t, Muon::HitsSoA) dev_muon_hits;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, uint) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_muon_compact_hit_t, uint64_t) dev_muon_compact_hit;
    DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits) dev_muon_raw_to_hits;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void muon_populate_hits(Parameters);

  template<typename T, char... S>
  struct muon_populate_hits_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(muon_populate_hits)) function {muon_populate_hits};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_muon_hits_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_permutation_station_t>(
        arguments, value<host_muon_total_number_of_hits_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_permutation_station_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_storage_tile_id_t>(arguments),
                    begin<dev_storage_tdc_value_t>(arguments),
                    begin<dev_permutation_station_t>(arguments),
                    begin<dev_muon_hits_t>(arguments),
                    begin<dev_station_ocurrences_offset_t>(arguments),
                    begin<dev_muon_compact_hit_t>(arguments),
                    begin<dev_muon_raw_to_hits_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace muon_populate_hits