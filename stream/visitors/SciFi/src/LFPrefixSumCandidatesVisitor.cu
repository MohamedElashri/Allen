#include "PrefixSumHandler.cuh"
#include "SequenceVisitor.cuh"
#include "CpuPrefixSum.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_prefix_sum_candidates_t>(
  lf_prefix_sum_candidates_t& state,
  lf_prefix_sum_candidates_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_prefix_sum_auxiliary_array_7>(lf_prefix_sum_candidates_t::aux_array_size(
    arguments.size<dev_scifi_lf_number_of_candidates>() / sizeof(dev_scifi_lf_number_of_candidates::type)));
}

template<>
void SequenceVisitor::visit<lf_prefix_sum_candidates_t>(
  lf_prefix_sum_candidates_t& state,
  const lf_prefix_sum_candidates_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  if (runtime_options.cpu_offload) {
    cpu_prefix_sum(
      host_buffers.host_prefix_sum_buffer,
      host_buffers.host_allocated_prefix_sum_space,
      arguments.offset<dev_scifi_lf_number_of_candidates>(),
      arguments.size<dev_scifi_lf_number_of_candidates>(),
      cuda_stream,
      cuda_generic_event,
      host_buffers.host_lf_total_number_of_candidates);
  }
  else {
    const auto number_of_ut_tracks = host_buffers.host_number_of_reconstructed_ut_tracks[0];

    // Set size of the main array to be prefix summed
    state.set_size(number_of_ut_tracks * LookingForward::number_of_x_layers);

    // Set the cuda_stream
    state.set_opts(cuda_stream);

    // Set arguments: Array to prefix sum and auxiliary array
    state.set_arguments(
      arguments.offset<dev_scifi_lf_number_of_candidates>(), arguments.offset<dev_prefix_sum_auxiliary_array_7>());

    // Invoke all steps of prefix sum
    state.invoke();

    // Fetch total number of hits accumulated with all windows
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_lf_total_number_of_candidates,
      arguments.offset<dev_scifi_lf_number_of_candidates>() + number_of_ut_tracks * LookingForward::number_of_x_layers,
      sizeof(int),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaEventRecord(cuda_generic_event, cuda_stream);
    cudaEventSynchronize(cuda_generic_event);
  }
}
