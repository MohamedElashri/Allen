#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "FindPermutation.cuh"

namespace muon_sort_station_region_quarter {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_INPUT(dev_storage_tdc_value_t, uint) dev_storage_tdc_value;
    DEVICE_INPUT(dev_atomics_muon_t, uint) dev_atomics_muon;
    DEVICE_OUTPUT(dev_permutation_srq_t, uint) dev_permutation_srq;
  };

  __global__ void muon_sort_station_region_quarter(Parameters);

  template<typename T>
  struct muon_sort_station_region_quarter_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"muon_sort_station_region_quarter_t"};
    decltype(global_function(muon_sort_station_region_quarter)) function {muon_sort_station_region_quarter};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_permutation_srq_t>(
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
        offset<dev_permutation_srq_t>(arguments), 0, size<dev_permutation_srq_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_storage_tile_id_t>(arguments),
                    offset<dev_storage_tdc_value_t>(arguments),
                    offset<dev_atomics_muon_t>(arguments),
                    offset<dev_permutation_srq_t>(arguments)});
    }
  };
} // namespace muon_sort_station_region_quarter