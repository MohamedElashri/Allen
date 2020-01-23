#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "FindPermutation.cuh"
#include "MuonRawToHits.cuh"

namespace muon_sort_by_station {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_INPUT(dev_storage_tdc_value_t, uint) dev_storage_tdc_value;
    DEVICE_INPUT(dev_atomics_muon_t, uint) dev_atomics_muon;
    DEVICE_OUTPUT(dev_permutation_station_t, uint) dev_permutation_station;
    DEVICE_OUTPUT(dev_muon_hits_t, Muon::HitsSoA) dev_muon_hits;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, uint) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_muon_compact_hit_t, uint64_t) dev_muon_compact_hit;
    DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits) dev_muon_raw_to_hits;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void muon_sort_by_station(Parameters);

  template<typename T, char... S>
  struct muon_sort_by_station_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(muon_sort_by_station)) function {muon_sort_by_station};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_permutation_station_t>(
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
        begin<dev_permutation_station_t>(arguments), 0, size<dev_permutation_station_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<blockdim_t>(), cuda_stream)(
        Parameters {begin<dev_storage_tile_id_t>(arguments),
                    begin<dev_storage_tdc_value_t>(arguments),
                    begin<dev_atomics_muon_t>(arguments),
                    begin<dev_permutation_station_t>(arguments),
                    begin<dev_muon_hits_t>(arguments),
                    begin<dev_station_ocurrences_offset_t>(arguments),
                    begin<dev_muon_compact_hit_t>(arguments),
                    begin<dev_muon_raw_to_hits_t>(arguments)});
    }

  private:
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace muon_sort_by_station