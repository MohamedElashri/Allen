#pragma once

#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "DeviceAlgorithm.cuh"

#define ECAL_BANKS 28
#define HCAL_BANKS 8
// #define CARD_CHANNELS 32
#define MAX_CELLID 0b100000000000000
#define CLUST_ITERATIONS 10


namespace calo_find_clusters {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_OUTPUT(dev_hcal_digits_t, CaloDigit) dev_hcal_digits;
    PROPERTY(block_dim_x_t, uint, "block_dim_x", "block dimension X", 32);
  };

  // Global function
  __global__ void calo_find_local_maxima(Parameters parameters, const uint number_of_events, 
    const char* raw_ecal_geometry, const char* raw_hcal_geometry);
  __global__ void calo_find_clusters(Parameters parameters, const uint number_of_events,
    const char* raw_ecal_geometry, const char* raw_hcal_geometry);

  // Algorithm
  template<typename T, char... S>
  struct calo_find_clusters_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(calo_find_local_maxima)) function_max {calo_find_local_maxima};
    decltype(global_function(calo_find_clusters)) function_cluster {calo_find_clusters};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ecal_digits_t>(arguments, MAX_CELLID);
      set_size<dev_hcal_digits_t>(arguments, MAX_CELLID);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      // Enough blocks to cover all events
      const auto grid_size = dim3(
        (value<host_number_of_selected_events_t>(arguments) + property<block_dim_x_t>() - 1) / property<block_dim_x_t>());

      // Invoke kernel
      const Parameters parameters{begin<dev_event_list_t>(arguments),
                                  begin<dev_ecal_digits_t>(arguments),
                                  begin<dev_hcal_digits_t>(arguments)};

      // Find local maxima.
      function_max(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
        parameters, value<host_number_of_selected_events_t>(arguments),
        constants.dev_ecal_geometry, constants.dev_hcal_geometry);

      // Find clusters.
      function_cluster(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
        parameters, value<host_number_of_selected_events_t>(arguments),
        constants.dev_ecal_geometry, constants.dev_hcal_geometry);
    }

  private:
    Property<block_dim_x_t> m_block_dim_x {this};
  };
} // namespace calo_find_clusters
