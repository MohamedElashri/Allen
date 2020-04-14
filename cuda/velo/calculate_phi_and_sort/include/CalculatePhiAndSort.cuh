#pragma once

#include <cstdint>
#include <cassert>
#include "CudaCommon.h"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "VeloTools.cuh"

namespace velo_calculate_phi_and_sort {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_total_number_of_velo_clusters_t, uint);
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_cluster_num_t, uint) dev_module_cluster_num;
    DEVICE_INPUT(dev_velo_cluster_container_t, char) dev_velo_cluster_container;
    DEVICE_OUTPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_OUTPUT(dev_hit_permutation_t, uint) dev_hit_permutation;
    DEVICE_OUTPUT(dev_hit_phi_t, int16_t) dev_hit_phi;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __device__ void calculate_phi(
    int16_t* shared_hit_phis,
    const uint* module_hitStarts,
    const uint* module_hitNums,
    Velo::ConstClusters& velo_cluster_container,
    int16_t* hit_Phis,
    uint* hit_permutations);

  __device__ void sort_by_phi(
    const uint event_hit_start,
    const uint event_number_of_hits,
    Velo::ConstClusters& velo_cluster_container,
    Velo::Clusters& velo_sorted_cluster_container,
    uint* hit_permutations);

  __global__ void velo_calculate_phi_and_sort(Parameters);

  template<typename T, char... S>
  struct velo_calculate_phi_and_sort_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(velo_calculate_phi_and_sort)) function {velo_calculate_phi_and_sort};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_sorted_velo_cluster_container_t>(arguments, size<dev_velo_cluster_container_t>(arguments));
      set_size<dev_hit_permutation_t>(arguments, value<host_total_number_of_velo_clusters_t>(arguments));
      set_size<dev_hit_phi_t>(arguments, value<host_total_number_of_velo_clusters_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_hit_permutation_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_offsets_estimated_input_size_t>(arguments),
                    begin<dev_module_cluster_num_t>(arguments),
                    begin<dev_velo_cluster_container_t>(arguments),
                    begin<dev_sorted_velo_cluster_container_t>(arguments),
                    begin<dev_hit_permutation_t>(arguments),
                    begin<dev_hit_phi_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };
} // namespace velo_calculate_phi_and_sort