#pragma once

#include "GpuAlgorithm.cuh"
#include "ClusteringDefinitions.cuh"

namespace velo_estimate_input_size {
  // Arguments
  HOST_INPUT(host_number_of_selected_events_t, uint)
  DEVICE_INPUT(dev_event_list_t, uint)
  DEVICE_OUTPUT(dev_velo_raw_input_t, char)
  DEVICE_OUTPUT(dev_velo_raw_input_offsets_t, uint)
  DEVICE_OUTPUT(dev_estimated_input_size_t, uint)
  DEVICE_OUTPUT(dev_module_candidate_num_t, uint)
  DEVICE_OUTPUT(dev_cluster_candidates_t, uint)

  // Global function
  __global__ void velo_estimate_input_size(
    dev_velo_raw_input_t dev_velo_raw_input,
    dev_velo_raw_input_offsets_t dev_velo_raw_input_offsets,
    dev_estimated_input_size_t dev_estimated_input_size,
    dev_module_candidate_num_t dev_module_candidate_num,
    dev_cluster_candidates_t dev_cluster_candidates,
    dev_event_list_t dev_event_list,
    uint8_t* candidate_ks);

  // Algorithm
  template<typename Arguments>
  struct velo_estimate_input_size_t : public DeviceAlgorithm {
    constexpr static auto name {"velo_estimate_input_size_t"};
    decltype(global_function(velo_estimate_input_size)) function {velo_estimate_input_size};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      if (logger::ll.verbosityLevel >= logger::debug) {
        debug_cout << "# of events = " << offset<host_number_of_selected_events_t>(arguments)[0] << std::endl;
      }

      set_size<dev_velo_raw_input_t>(arguments, std::get<0>(runtime_options.host_velo_events).size_bytes());
      set_size<dev_velo_raw_input_offsets_t>(arguments, std::get<1>(runtime_options.host_velo_events).size_bytes());
      set_size<dev_estimated_input_size_t>(
        arguments, offset<host_number_of_selected_events_t>(arguments)[0] * Velo::Constants::n_modules + 1);
      set_size<dev_module_candidate_num_t>(arguments, offset<host_number_of_selected_events_t>(arguments)[0]);
      set_size<dev_cluster_candidates_t>(
        arguments, offset<host_number_of_selected_events_t>(arguments)[0] * VeloClustering::max_candidates_event);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      cudaCheck(cudaMemcpyAsync(
        offset<dev_velo_raw_input_t>(arguments),
        std::get<0>(runtime_options.host_velo_events).begin(),
        std::get<0>(runtime_options.host_velo_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));
      cudaCheck(cudaMemcpyAsync(
        offset<dev_velo_raw_input_offsets_t>(arguments),
        std::get<1>(runtime_options.host_velo_events).begin(),
        std::get<1>(runtime_options.host_velo_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        offset<dev_estimated_input_size_t>(arguments), 0, size<dev_estimated_input_size_t>(arguments), cuda_stream));
      cudaCheck(cudaMemsetAsync(
        offset<dev_module_candidate_num_t>(arguments), 0, size<dev_module_candidate_num_t>(arguments), cuda_stream));

      // Invoke kernel
      function(dim3(offset<host_number_of_selected_events_t>(arguments)[0]), block_dimension(), cuda_stream)(
        offset<dev_velo_raw_input_t>(arguments),
        offset<dev_velo_raw_input_offsets_t>(arguments),
        offset<dev_estimated_input_size_t>(arguments),
        offset<dev_module_candidate_num_t>(arguments),
        offset<dev_cluster_candidates_t>(arguments),
        offset<dev_event_list_t>(arguments),
        constants.dev_velo_candidate_ks.data());
    }
  };
} // namespace velo_estimate_input_size