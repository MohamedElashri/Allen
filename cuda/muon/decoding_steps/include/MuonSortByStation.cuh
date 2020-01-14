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
  };

  __global__ void muon_sort_by_station(Parameters);

  template<typename T>
  struct muon_sort_by_station_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"muon_sort_by_station_t"};
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
        offset<dev_permutation_station_t>(arguments), 0, size<dev_permutation_station_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_storage_tile_id_t>(arguments),
                    offset<dev_storage_tdc_value_t>(arguments),
                    offset<dev_atomics_muon_t>(arguments),
                    offset<dev_permutation_station_t>(arguments),
                    offset<dev_muon_hits_t>(arguments),
                    offset<dev_station_ocurrences_offset_t>(arguments),
                    offset<dev_muon_compact_hit_t>(arguments),
                    offset<dev_muon_raw_to_hits_t>(arguments)});
    }
  };
} // namespace muon_sort_by_station