#pragma once

#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "CaloCluster.cuh"
#include "DeviceAlgorithm.cuh"

#define ECAL_BANKS 28
#define HCAL_BANKS 8
#define ECAL_MAX_CELLID 0b11000000000000
#define HCAL_MAX_CELLID 0b10000000000000
#define CLUST_ITERATIONS 10


namespace calo_find_clusters {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_ecal_number_of_clusters_t, uint);
    HOST_INPUT(host_hcal_number_of_clusters_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, uint) dev_ecal_cluster_offsets;
    DEVICE_INPUT(dev_hcal_cluster_offsets_t, uint) dev_hcal_cluster_offsets;
    DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_OUTPUT(dev_hcal_digits_t, CaloDigit) dev_hcal_digits;
    DEVICE_OUTPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_OUTPUT(dev_hcal_clusters_t, CaloCluster) dev_hcal_clusters;
    PROPERTY(block_dim_x_t, uint, "block_dim_x", "block dimension X", 32);
  };

  // Global function
  __global__ void calo_find_clusters(Parameters parameters, const uint number_of_events,
    const char* raw_ecal_geometry, const char* raw_hcal_geometry);

  // Algorithm
  template<typename T, char... S>
  struct calo_find_clusters_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(calo_find_clusters)) function_cluster {calo_find_clusters};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {

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
                                  begin<dev_ecal_cluster_offsets_t>(arguments),
                                  begin<dev_hcal_cluster_offsets_t>(arguments),
                                  begin<dev_ecal_digits_t>(arguments),
                                  begin<dev_hcal_digits_t>(arguments),
                                  begin<dev_ecal_clusters_t>(arguments),
                                  begin<dev_hcal_clusters_t>(arguments)};

      // Find clusters.
      function_cluster(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
        parameters, value<host_number_of_selected_events_t>(arguments),
        constants.dev_ecal_geometry, constants.dev_hcal_geometry);
    }

  private:
    Property<block_dim_x_t> m_block_dim_x {this};
  };
} // namespace calo_find_clusters
