#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "FindPermutation.cuh"
#include "MuonTileID.cuh"

namespace muon_sort_station_region_quarter {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_storage_tile_id_t, uint) dev_storage_tile_id;
    DEVICE_OUTPUT(dev_storage_tdc_value_t, uint) dev_storage_tdc_value;
    DEVICE_INPUT(dev_atomics_muon_t, uint) dev_atomics_muon;
    DEVICE_OUTPUT(dev_permutation_srq_t, uint) dev_permutation_srq;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void muon_sort_station_region_quarter(Parameters);

  template<typename T, char... S>
  struct muon_sort_station_region_quarter_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
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
      initialize<dev_permutation_srq_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_storage_tile_id_t>(arguments),
                    begin<dev_storage_tdc_value_t>(arguments),
                    begin<dev_atomics_muon_t>(arguments),
                    begin<dev_permutation_srq_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace muon_sort_station_region_quarter