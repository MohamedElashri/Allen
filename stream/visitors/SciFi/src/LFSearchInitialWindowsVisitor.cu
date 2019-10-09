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
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::number_of_x_layers * 8);
  arguments.set_size<dev_ut_states>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
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
    arguments.offset<dev_scifi_lf_initial_windows>(), 0, arguments.size<dev_scifi_lf_initial_windows>(), cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_velo_states>(),
    arguments.offset<dev_atomics_ut>(),
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
}
