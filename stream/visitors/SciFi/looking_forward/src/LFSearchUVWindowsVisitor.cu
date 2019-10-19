#include "LFSearchUVWindows.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_search_uv_windows_t>(
  lf_search_uv_windows_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  // 6 layers
  // 2 elements on each window
  arguments.set_size<dev_scifi_lf_uv_windows>(
    2 * 6 * host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter);
}

template<>
void SequenceVisitor::visit<lf_search_uv_windows_t>(
  lf_search_uv_windows_t& state,
  const lf_search_uv_windows_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_uv_windows>(), 0, arguments.size<dev_scifi_lf_uv_windows>(), cuda_stream));

  // 32 - 18.42% 13.0076s, 39822.61 events/s
  // 256 - 9.47% 6.01868s, 38491.16 events/s

  state.set_opts(
    dim3(host_buffers.host_number_of_selected_events[0]), dim3(128), cuda_stream);

  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_lf_x_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_x_filtered_atomics>(),
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_inv_clus_res,
    arguments.offset<dev_ut_states>(),
    arguments.offset<dev_scifi_lf_uv_windows>(),
    arguments.offset<dev_scifi_lf_initial_windows>());

  // Forward to UV layers
  state.invoke();
}
