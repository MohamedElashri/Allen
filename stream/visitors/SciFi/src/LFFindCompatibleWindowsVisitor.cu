#include "LFFindCompatibleWindows.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_find_compatible_windows_t>(
  lf_find_compatible_windows_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  // 2 windows of size 2
  arguments.set_size<dev_scifi_lf_compatible_windows>(host_buffers.host_lf_total_number_of_candidates[0] * 2 * 2);
}

template<>
void SequenceVisitor::visit<lf_find_compatible_windows_t>(
  lf_find_compatible_windows_t& state,
  const lf_find_compatible_windows_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_compatible_windows>(),
    0,
    arguments.size<dev_scifi_lf_compatible_windows>(),
    cuda_stream));

  // Scan:
  // 64, 8 - 14.03%
  // 32, 8, 2 - 8.27%
  // 32, 8, 4 - 6.74%
  // 16, 8, 8 - 7.26%
  // 32, 4, 8 - 8.19%
  // 64, 4, 4 - 7.03%

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(32, 8, 4), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_states>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_initial_windows>(),
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    arguments.offset<dev_scifi_lf_candidates>(),
    arguments.offset<dev_scifi_lf_compatible_windows>(),
    constants.dev_looking_forward_constants);

  state.invoke();

  // std::vector<short> windows (arguments.size<dev_scifi_lf_compatible_windows>() / sizeof(short));
  // std::vector<int> number_of_candidates (arguments.size<dev_scifi_lf_number_of_candidates>() / sizeof(uint));

  // cudaCheck(cudaMemcpy(
  //   windows.data(),
  //   arguments.offset<dev_scifi_lf_compatible_windows>(),
  //   arguments.size<dev_scifi_lf_compatible_windows>(),
  //   cudaMemcpyDeviceToHost));

  // cudaCheck(cudaMemcpy(
  //   number_of_candidates.data(),
  //   arguments.offset<dev_scifi_lf_number_of_candidates>(),
  //   arguments.size<dev_scifi_lf_number_of_candidates>(),
  //   cudaMemcpyDeviceToHost));

  // for (size_t event_number=0; event_number<host_buffers.host_number_of_selected_events[0]; ++event_number) {
  //   const auto offset = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number];
  //   // const auto number_of_ut_tracks = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number+1] - offset;

  //   info_cout << "Event #" << event_number << std::endl;
  //   for (size_t i=0; i<2; ++i) {
  //     const auto current_track_index = offset + i;
  //     info_cout << " Track #" << i << ":" << std::endl;

  //     for (int j=0; j<8; ++j) {
  //       const uint8_t relative_layer_direction = j % 2;
  //       const uint8_t relative_layer_from = (j >> 1) + 1;
  //       // const uint8_t relative_layer_to = relative_layer_from + 2 * (j % 2) - 1;
  //       const uint8_t layer_from = (relative_layer_from / 2) * 4 + (relative_layer_from % 2) * 3;
  //       const uint8_t layer_to = (j % 2) * 4 + (j >> 2) * 4 + ((j >> 1) % 2) * 3;

  //       info_cout << "  Candidates from layer " << ((int) layer_from) << " to layer " << ((int) layer_to) << ":" << std::endl;

  //       const auto candidate_offset = number_of_candidates[current_track_index * LookingForward::number_of_x_layers + relative_layer_from];
  //       const auto n_candidates = number_of_candidates[current_track_index * LookingForward::number_of_x_layers + relative_layer_from + 1] - candidate_offset;

  //       for (int k=0; k<n_candidates; ++k) {
  //         const auto first_candidate_in_window = windows[
  //           relative_layer_direction * host_buffers.host_lf_total_number_of_candidates[0] +
  //           candidate_offset + k];

  //         const auto window_size = windows[
  //           (2 + relative_layer_direction) * host_buffers.host_lf_total_number_of_candidates[0] +
  //           candidate_offset + k];

  //         // if (window_size > 0) {
  //         info_cout << "   #" << k << ": " << first_candidate_in_window << ", " << window_size << std::endl;
  //         // }
  //       }
  //     }

  //     info_cout << std::endl;
  //   }
  // }
}
