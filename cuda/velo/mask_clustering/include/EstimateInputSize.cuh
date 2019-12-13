#pragma once

#include "GpuAlgorithm.cuh"
#include "ClusteringDefinitions.cuh"

namespace velo_estimate_input_size {
  // Arguments
  struct event_list_t : input_datatype<uint> {};
  struct velo_raw_input_t : output_datatype<char> {};
  struct velo_raw_input_offsets_t : output_datatype<uint> {};
  struct estimated_input_size_t : output_datatype<uint> {};
  struct module_candidate_num_t : output_datatype<uint> {};
  struct cluster_candidates_t : output_datatype<uint> {};

  // Global function
  __global__ void velo_estimate_input_size(
    velo_raw_input_t velo_raw_input,
    velo_raw_input_offsets_t velo_raw_input_offsets,
    estimated_input_size_t estimated_input_size,
    module_candidate_num_t module_candidate_num,
    cluster_candidates_t cluster_candidates,
    event_list_t event_list,
    uint8_t* candidate_ks);

  // Algorithm
  template<typename Arguments>
  struct velo_estimate_input_size_t : public GpuAlgorithm
  {
    constexpr static auto name {"velo_estimate_input_size_t"};
    decltype(gpu_function(velo_estimate_input_size)) function {velo_estimate_input_size};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      if (logger::ll.verbosityLevel >= logger::debug) {
        debug_cout << "# of events = " << host_buffers.host_number_of_selected_events[0] << std::endl;
      }

      set_size<velo_raw_input_t>(arguments, std::get<0>(runtime_options.host_velo_events).size_bytes());
      set_size<velo_raw_input_offsets_t>(arguments, std::get<1>(runtime_options.host_velo_events).size_bytes());
      set_size<estimated_input_size_t>(arguments,
        host_buffers.host_number_of_selected_events[0] * Velo::Constants::n_modules + 1);
      // set_size<module_cluster_num_t>(arguments,
      //   host_buffers.host_number_of_selected_events[0] * Velo::Constants::n_modules);
      set_size<module_candidate_num_t>(arguments,host_buffers.host_number_of_selected_events[0]);
      set_size<cluster_candidates_t>(arguments,
        host_buffers.host_number_of_selected_events[0] * VeloClustering::max_candidates_event);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemcpyAsync(
        offset<velo_raw_input_t>(arguments),
        std::get<0>(runtime_options.host_velo_events).begin(),
        std::get<0>(runtime_options.host_velo_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));
      cudaCheck(cudaMemcpyAsync(
        offset<velo_raw_input_offsets_t>(arguments),
        std::get<1>(runtime_options.host_velo_events).begin(),
        std::get<1>(runtime_options.host_velo_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        offset<estimated_input_size_t>(arguments),
        0,
        size<estimated_input_size_t>(arguments),
        cuda_stream));
      // cudaCheck(cudaMemsetAsync(
      //   offset<module_cluster_num_t>(arguments),
      //   0,
      //   size<module_cluster_num_t>(arguments),
      //   cuda_stream));
      cudaCheck(cudaMemsetAsync(
        offset<module_candidate_num_t>(arguments),
        0,
        size<module_candidate_num_t>(arguments),
        cuda_stream));

      // Invoke kernel
      function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
        offset<velo_raw_input_t>(arguments),
        offset<velo_raw_input_offsets_t>(arguments),
        offset<estimated_input_size_t>(arguments),
        offset<module_candidate_num_t>(arguments),
        offset<cluster_candidates_t>(arguments),
        offset<event_list_t>(arguments),
        constants.dev_velo_candidate_ks.data());
    }
  };
}