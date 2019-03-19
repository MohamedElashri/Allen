#include "PrefixSumHandler.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_prefix_sum_candidates_t>(
  lf_prefix_sum_candidates_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_prefix_sum_auxiliary_array_7>(
    lf_prefix_sum_candidates_t::aux_array_size(arguments.size<dev_scifi_lf_number_of_candidates>() /
        sizeof(dev_scifi_lf_number_of_candidates::type)));
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
  const auto number_of_ut_tracks = host_buffers.host_atomics_ut[2 * host_buffers.host_number_of_selected_events[0]];

  // Set size of the main array to be prefix summed
  state.set_size(number_of_ut_tracks * LookingForward::number_of_x_layers);

  // Set the cuda_stream
  state.set_opts(cuda_stream);

  // Set arguments: Array to prefix sum and auxiliary array
  state.set_arguments(
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    arguments.offset<dev_prefix_sum_auxiliary_array_7>());

  // Invoke all steps of prefix sum
  state.invoke();

  // Fetch total number of hits accumulated with all windows
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_lf_total_number_of_candidates,
    arguments.offset<dev_scifi_lf_number_of_candidates>()
    + number_of_ut_tracks * LookingForward::number_of_x_layers,
    sizeof(int),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);

  // std::vector<int> number_of_candidates (arguments.size<dev_scifi_lf_number_of_candidates>() / sizeof(int));

  // cudaCheck(cudaMemcpy(
  //   number_of_candidates.data(),
  //   arguments.offset<dev_scifi_lf_number_of_candidates>(),
  //   arguments.size<dev_scifi_lf_number_of_candidates>(),
  //   cudaMemcpyDeviceToHost));

  // // const auto ut_total_number_of_tracks = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] * 2];
  // for (size_t event_number=0; event_number<host_buffers.host_number_of_selected_events[0]; ++event_number) {
  //   const auto offset = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number];
  //   const auto number_of_ut_tracks = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number+1] - offset;

  //   info_cout << "Event #" << event_number << std::endl;
  //   for (size_t i=0; i<number_of_ut_tracks; ++i) {
  //     info_cout << "Candidates track #" << i << ": ";

  //     for (int j=0; j<LookingForward::number_of_x_layers; ++j) {
  //       info_cout << number_of_candidates[(offset + i) * LookingForward::number_of_x_layers + j] << ", ";
  //     }

  //     info_cout << std::endl;
  //   }
  // }
}
