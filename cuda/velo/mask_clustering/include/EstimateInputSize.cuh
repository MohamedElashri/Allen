#pragma once

#include "DeviceAlgorithm.cuh"
#include "ClusteringDefinitions.cuh"

namespace velo_estimate_input_size {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_velo_raw_input_t, char) dev_velo_raw_input;
    DEVICE_OUTPUT(dev_velo_raw_input_offsets_t, uint) dev_velo_raw_input_offsets;
    DEVICE_OUTPUT(dev_estimated_input_size_t, uint) dev_estimated_input_size;
    DEVICE_OUTPUT(dev_module_candidate_num_t, uint) dev_module_candidate_num;
    DEVICE_OUTPUT(dev_cluster_candidates_t, uint) dev_cluster_candidates;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {16, 16, 1});
  };

  // Global function
  __global__ void velo_estimate_input_size(Parameters parameters, const uint8_t* candidate_ks);
  __global__ void velo_estimate_input_size_mep(Parameters parameters, const uint8_t* candidate_ks);

  // Algorithm
  template<typename T, char... S>
  struct velo_estimate_input_size_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(velo_estimate_input_size)) function {velo_estimate_input_size};
    decltype(global_function(velo_estimate_input_size_mep)) function_mep {velo_estimate_input_size_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      if (logger::ll.verbosityLevel >= logger::debug) {
        debug_cout << "# of events = " << value<host_number_of_selected_events_t>(arguments) << std::endl;
      }

      set_size<dev_velo_raw_input_t>(arguments, std::get<1>(runtime_options.host_velo_events));
      set_size<dev_velo_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_velo_events).size_bytes() / sizeof(uint));
      set_size<dev_estimated_input_size_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Velo::Constants::n_modules);
      set_size<dev_module_candidate_num_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_cluster_candidates_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * VeloClustering::max_candidates_event);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      data_to_device<dev_velo_raw_input_t, dev_velo_raw_input_offsets_t>
        (arguments, runtime_options.host_velo_events, cuda_stream);

      cudaCheck(cudaMemsetAsync(
        begin<dev_estimated_input_size_t>(arguments), 0, size<dev_estimated_input_size_t>(arguments), cuda_stream));
      cudaCheck(cudaMemsetAsync(
        begin<dev_module_candidate_num_t>(arguments), 0, size<dev_module_candidate_num_t>(arguments), cuda_stream));

      // Invoke kernel
      const auto parameters = Parameters {begin<dev_event_list_t>(arguments),
                                          begin<dev_velo_raw_input_t>(arguments),
                                          begin<dev_velo_raw_input_offsets_t>(arguments),
                                          begin<dev_estimated_input_size_t>(arguments),
                                          begin<dev_module_candidate_num_t>(arguments),
                                          begin<dev_cluster_candidates_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters, constants.dev_velo_candidate_ks.data());
      }
      else {
        function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters, constants.dev_velo_candidate_ks.data());
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace velo_estimate_input_size
// =======
// #include "Handler.cuh"
// #include "ArgumentsCommon.cuh"
// #include "ArgumentsVelo.cuh"

// __global__ void estimate_input_size(
//   char* dev_raw_input,
//   uint* dev_raw_input_offsets,
//   uint* dev_estimated_input_size,
//   uint* dev_module_candidate_num,
//   uint32_t* dev_cluster_candidates,
//   const uint* dev_event_list,
//   uint8_t* dev_velo_candidate_ks);

// ALGORITHM(
//   estimate_input_size,
//   velo_estimate_input_size_allen_t,
//   ARGUMENTS(
//     dev_velo_raw_input,
//     dev_velo_raw_input_offsets,
//     dev_estimated_input_size,
//     dev_module_cluster_num,
//     dev_module_candidate_num,
//     dev_cluster_candidates,
//     dev_event_list))

// __global__ void estimate_input_size_mep(
//   char* dev_raw_input,
//   uint* dev_raw_input_offsets,
//   uint* dev_estimated_input_size,
//   uint* dev_module_candidate_num,
//   uint32_t* dev_cluster_candidates,
//   const uint* dev_event_list,
//   uint8_t* dev_velo_candidate_ks);

// ALGORITHM(
//   estimate_input_size_mep,
//   velo_estimate_input_size_mep_t,
//   ARGUMENTS(
//     dev_velo_raw_input,
//     dev_velo_raw_input_offsets,
//     dev_estimated_input_size,
//     dev_module_cluster_num,
//     dev_module_candidate_num,
//     dev_cluster_candidates,
//     dev_event_list))

// XOR_ALGORITHM(velo_estimate_input_size_mep_t,
//               velo_estimate_input_size_allen_t,
//               velo_estimate_input_size_t)
// >>>>>>> origin/raaij_mep_decoding
