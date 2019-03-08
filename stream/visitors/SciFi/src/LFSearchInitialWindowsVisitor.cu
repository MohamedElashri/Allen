#include "LFSearchInitialWindows.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_search_initial_windows_t>(
  lf_search_initial_windows_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_initial_windows>(
    host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] * 2]
    * host_buffers.host_number_of_selected_events[0]
    * 8 * SciFi::Tracking::zoneoffsetpar);
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
    -1,
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
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    constants.dev_scifi_constArrays,
    arguments.offset<dev_scifi_lf_initial_windows>());

  state.invoke();

  std::vector<int> host_forward_windows (arguments.size<dev_scifi_lf_initial_windows>() / sizeof(int));

  cudaCheck(cudaMemcpy(
    host_forward_windows.data(),
    arguments.offset<dev_scifi_lf_initial_windows>(),
    arguments.size<dev_scifi_lf_initial_windows>(),
    cudaMemcpyDeviceToHost));

  const auto ut_total_number_of_tracks = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] * 2];

  for (size_t event_number=0; event_number<host_buffers.host_number_of_selected_events[0]; ++event_number) {
    const auto offset = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number];
    const auto size = host_buffers.host_atomics_ut[host_buffers.host_number_of_selected_events[0] + event_number+1] - offset;

    info_cout << "Event #" << event_number << std::endl;

    for (size_t i_veloUT_track=0; i_veloUT_track<size; ++i_veloUT_track) {
      info_cout << " Track #" << i_veloUT_track << std::endl;
      info_cout << "  Side yAtRef > -5.f:" << std::endl << "   ";

      for (int i = 0; i < 4 * SciFi::Tracking::zoneoffsetpar; ++i) {
        info_cout << host_forward_windows[
          i * host_buffers.host_number_of_selected_events[0] * ut_total_number_of_tracks +
          offset +
          i_veloUT_track
          ] << ", " << std::flush;
      }
      info_cout << std::endl;
      info_cout << "  Side yAtRef < 5.f:" << std::endl << "   ";

      for (int i = 0; i < 4 * SciFi::Tracking::zoneoffsetpar; ++i) {
        info_cout << host_forward_windows[
          4 * SciFi::Tracking::zoneoffsetpar * host_buffers.host_number_of_selected_events[0] * ut_total_number_of_tracks +
          i * host_buffers.host_number_of_selected_events[0] * ut_total_number_of_tracks +
          offset +
          i_veloUT_track
          ] << ", ";
      }
      info_cout << std::endl;
    }
  }
}
