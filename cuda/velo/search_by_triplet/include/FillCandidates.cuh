#pragma once

#include "DeviceAlgorithm.cuh"

namespace velo_fill_candidates {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_total_number_of_velo_clusters_t, uint);
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, uint) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_cluster_num_t, uint) dev_module_cluster_num;
    DEVICE_INPUT(dev_hit_phi_t, float) dev_hit_phi;
    DEVICE_OUTPUT(dev_h0_candidates_t, short) dev_h0_candidates;
    DEVICE_OUTPUT(dev_h2_candidates_t, short) dev_h2_candidates;

    // These parameters impact the found tracks
    // Maximum / minimum acceptable phi
    // These two parameters impacts enourmously the speed of track seeding
    PROPERTY(phi_extrapolation_base_t, float, "phi_extrapolation_base", "phi extrapolation base", 0.03f)
    phi_extrapolation_base;

    // A higher coefficient improves efficiency at the
    // cost of performance
    PROPERTY(phi_extrapolation_coef_t, float, "phi_extrapolation_coef", "phi extrapolation coefficient", 0.0002f)
    phi_extrapolation_coef;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {128, 1, 1});
  };

  __global__ void velo_fill_candidates(Parameters);

  template<typename T, char... S>
  struct velo_fill_candidates_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(velo_fill_candidates)) function {velo_fill_candidates};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_h0_candidates_t>(arguments, 2 * value<host_total_number_of_velo_clusters_t>(arguments));
      set_size<dev_h2_candidates_t>(arguments, 2 * value<host_total_number_of_velo_clusters_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(
        cudaMemsetAsync(begin<dev_h0_candidates_t>(arguments), 0, size<dev_h0_candidates_t>(arguments), cuda_stream));
      cudaCheck(
        cudaMemsetAsync(begin<dev_h2_candidates_t>(arguments), 0, size<dev_h2_candidates_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments), 48), property<blockdim_t>(), cuda_stream)(
        Parameters {begin<dev_sorted_velo_cluster_container_t>(arguments),
                    begin<dev_offsets_estimated_input_size_t>(arguments),
                    begin<dev_module_cluster_num_t>(arguments),
                    begin<dev_hit_phi_t>(arguments),
                    begin<dev_h0_candidates_t>(arguments),
                    begin<dev_h2_candidates_t>(arguments),
                    property<phi_extrapolation_base_t>(),
                    property<phi_extrapolation_coef_t>()});
    }

  private:
    Property<phi_extrapolation_base_t> m_ext_base {this};
    Property<phi_extrapolation_coef_t> m_ext_coef {this};
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace velo_fill_candidates