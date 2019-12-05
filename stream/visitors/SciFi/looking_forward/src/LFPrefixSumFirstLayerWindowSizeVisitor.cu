#include "PrefixSumHandler.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_prefix_sum_first_layer_window_size_t>(
  const lf_prefix_sum_first_layer_window_size_t& state,
  lf_prefix_sum_first_layer_window_size_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  const auto number_of_ut_tracks = host_buffers.host_number_of_reconstructed_ut_tracks[0];
  arguments.set_size<dev_prefix_sum_auxiliary_array_7>(
    lf_prefix_sum_first_layer_window_size_t::aux_array_size(number_of_ut_tracks));
}

template<>
void SequenceVisitor::visit<lf_prefix_sum_first_layer_window_size_t>(
  lf_prefix_sum_first_layer_window_size_t& state,
  const lf_prefix_sum_first_layer_window_size_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  const auto number_of_ut_tracks = host_buffers.host_number_of_reconstructed_ut_tracks[0];

  // Set size of the main array to be prefix summed
  state.set_size(number_of_ut_tracks);

  // Set the cuda_stream
  state.set_opts(cuda_stream);

  // Set arguments: Array to prefix sum and auxiliary array
  state.set_arguments(
    arguments.offset<dev_scifi_lf_first_layer_candidates>() + number_of_ut_tracks,
    arguments.offset<dev_prefix_sum_auxiliary_array_7>());

  // Invoke all steps of prefix sum
  state.invoke();

  // Fetch total number of hits accumulated with all windows
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_lf_total_size_first_window_layer,
    arguments.offset<dev_scifi_lf_first_layer_candidates>() + 2 * number_of_ut_tracks,
    sizeof(int),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);
}
