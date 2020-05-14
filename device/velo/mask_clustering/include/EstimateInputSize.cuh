#pragma once

#include "DeviceAlgorithm.cuh"
#include "ClusteringDefinitions.cuh"

namespace velo_estimate_input_size {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_cluster_candidates_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_candidates_offsets_t, uint) dev_candidates_offsets;
    DEVICE_INPUT(dev_velo_raw_input_t, char) dev_velo_raw_input;
    DEVICE_INPUT(dev_velo_raw_input_offsets_t, uint) dev_velo_raw_input_offsets;
    DEVICE_OUTPUT(dev_estimated_input_size_t, uint) dev_estimated_input_size;
    DEVICE_OUTPUT(dev_module_candidate_num_t, uint) dev_module_candidate_num;
    DEVICE_OUTPUT(dev_cluster_candidates_t, uint) dev_cluster_candidates;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };

  // Global function
  __global__ void velo_estimate_input_size(Parameters parameters);
  __global__ void velo_estimate_input_size_mep(Parameters parameters);

  // Algorithm
  template<typename T>
  struct velo_estimate_input_size_t : public DeviceAlgorithm, Parameters {
    decltype(global_function(velo_estimate_input_size)) function {velo_estimate_input_size};
    decltype(global_function(velo_estimate_input_size_mep)) function_mep {velo_estimate_input_size_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      if (logger::verbosity() >= logger::debug) {
        debug_cout << "# of events = " << first<host_number_of_selected_events_t>(arguments) << std::endl;
      }

      set_size<dev_estimated_input_size_t>(
        arguments, first<host_number_of_selected_events_t>(arguments) * Velo::Constants::n_module_pairs);
      set_size<dev_module_candidate_num_t>(arguments, first<host_number_of_selected_events_t>(arguments));
      set_size<dev_cluster_candidates_t>(arguments, first<host_number_of_cluster_candidates_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_estimated_input_size_t>(arguments, 0, cuda_stream);
      initialize<dev_module_candidate_num_t>(arguments, 0, cuda_stream);

      // Invoke kernel
      const auto parameters = Parameters {data<dev_event_list_t>(arguments),
                                          data<dev_candidates_offsets_t>(arguments),
                                          data<dev_velo_raw_input_t>(arguments),
                                          data<dev_velo_raw_input_offsets_t>(arguments),
                                          data<dev_estimated_input_size_t>(arguments),
                                          data<dev_module_candidate_num_t>(arguments),
                                          data<dev_cluster_candidates_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters);
      }
      else {
        function(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters);
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{16, 16, 1}}};
  };
} // namespace velo_estimate_input_size
