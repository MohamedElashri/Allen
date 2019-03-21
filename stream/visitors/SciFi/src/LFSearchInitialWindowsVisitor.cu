#include "LFSearchInitialWindows.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_search_initial_windows_t>(
  lf_search_initial_windows_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  const auto total_number_of_ut_tracks = host_buffers.host_atomics_ut[2 * host_buffers.host_number_of_selected_events[0]];
  arguments.set_size<dev_scifi_lf_initial_windows>(total_number_of_ut_tracks * LookingForward::number_of_x_layers * 8);
  arguments.set_size<dev_ut_states>(total_number_of_ut_tracks);
}

template<>
void SequenceVisitor::visit<lf_search_initial_windows_t>(
  lf_search_initial_windows_t& state,
  const lf_search_initial_windows_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_initial_windows>(),
    0,
    arguments.size<dev_scifi_lf_initial_windows>(),
    cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_velo_states>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hits>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_x>(),
    arguments.offset<dev_ut_tx>(),
    arguments.offset<dev_ut_z>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    constants.dev_scifi_constArrays,
    constants.dev_looking_forward_constants,
    arguments.offset<dev_scifi_lf_initial_windows>(),
    arguments.offset<dev_ut_states>());

  state.invoke();

  // std::vector<int> host_forward_windows (arguments.size<dev_scifi_lf_initial_windows>() / sizeof(int));

  // cudaCheck(cudaMemcpy(
  //   host_forward_windows.data(),
  //   arguments.offset<dev_scifi_lf_initial_windows>(),
  //   arguments.size<dev_scifi_lf_initial_windows>(),
  //   cudaMemcpyDeviceToHost));

  // const float* host_forward_windows_f = (float*) &host_forward_windows[0];
  // const auto ut_total_number_of_tracks = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] * 2];
  // for (size_t event_number=0; event_number<host_buffers.host_number_of_selected_events[0]; ++event_number) {
  //   const auto offset = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number];
  //   const auto number_of_ut_tracks = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number+1] - offset;

  //   info_cout << "Event #" << event_number << std::endl;
  //   for (size_t i=0; i<number_of_ut_tracks; ++i) {
  //     info_cout << "#" << i << ":" << std::endl;
  //     for (int j=0; j<SciFi::Tracking::zoneoffsetpar; ++j) {
  //       info_cout << " {" << host_forward_windows[(j * 8 + 0) * ut_total_number_of_tracks + offset + i] << ", "
  //         << host_forward_windows[(j * 8 + 1) * ut_total_number_of_tracks + offset + i] << "}, {"
  //         << host_forward_windows[(j * 8 + 2) * ut_total_number_of_tracks + offset + i] << ", "
  //         << host_forward_windows[(j * 8 + 3) * ut_total_number_of_tracks + offset + i] << "}, {"
  //         << host_forward_windows_f[(j * 8 + 4) * ut_total_number_of_tracks + offset + i] << ", "
  //         << host_forward_windows_f[(j * 8 + 5) * ut_total_number_of_tracks + offset + i] << ", "
  //         << host_forward_windows_f[(j * 8 + 6) * ut_total_number_of_tracks + offset + i] << ", "
  //         << host_forward_windows_f[(j * 8 + 7) * ut_total_number_of_tracks + offset + i] << "}"
  //         << std::endl;
  //     }

  //     info_cout << std::endl;
  //   }
  // }
}
