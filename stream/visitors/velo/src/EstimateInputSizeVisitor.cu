#include "SequenceVisitor.cuh"
#include "EstimateInputSize.cuh"

template<>
void SequenceVisitor::set_arguments_size<velo_estimate_input_size_t>(
  const velo_estimate_input_size_t& state,
  velo_estimate_input_size_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  if (logger::ll.verbosityLevel >= logger::debug) {
    debug_cout << "# of events = " << host_buffers.host_number_of_selected_events[0] << std::endl;
  }

  arguments.set_size<dev_estimated_input_size>(
    host_buffers.host_number_of_selected_events[0] * Velo::Constants::n_modules + 1);
  arguments.set_size<dev_module_cluster_num>(
    host_buffers.host_number_of_selected_events[0] * Velo::Constants::n_modules);
  arguments.set_size<dev_module_candidate_num>(host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_cluster_candidates>(
    host_buffers.host_number_of_selected_events[0] * VeloClustering::max_candidates_event);
}

template<>
void SequenceVisitor::visit<velo_estimate_input_size_t>(
  velo_estimate_input_size_t& state,
  const velo_estimate_input_size_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_estimated_input_size>(), 0, arguments.size<dev_estimated_input_size>(), cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_module_cluster_num>(), 0, arguments.size<dev_module_cluster_num>(), cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_module_candidate_num>(), 0, arguments.size<dev_module_candidate_num>(), cuda_stream));

  // Setup opts and arguments for kernel call
  state.set_opts(runtime_options.mep_layout, dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);

  state.set_arguments(
    runtime_options.mep_layout,
    arguments.offset<dev_velo_raw_input>(),
    arguments.offset<dev_velo_raw_input_offsets>(),
    arguments.offset<dev_estimated_input_size>(),
    arguments.offset<dev_module_candidate_num>(),
    arguments.offset<dev_cluster_candidates>(),
    arguments.offset<dev_event_list>(),
    constants.dev_velo_candidate_ks.data());

  // Kernel call
  state.invoke(runtime_options.mep_layout);
}
