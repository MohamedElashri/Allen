#include "LFCalculateTrackExtrapolationWindow.cuh"
#include "SequenceVisitor.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(lf_calculate_track_extrapolation_window_t)

template<>
void SequenceVisitor::visit<lf_calculate_track_extrapolation_window_t>(
  lf_calculate_track_extrapolation_window_t& state,
  const lf_calculate_track_extrapolation_window_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  // TODO: Maybe we don't need this, but for now, keeping it
  cudaCheck(
    cudaMemsetAsync(
      arguments.offset<dev_extrapolation_layer_candidates>(),
      0,
      arguments.size<dev_extrapolation_layer_candidates>(),
      cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_tracks>(),
    arguments.offset<dev_atomics_scifi>(),
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_inv_clus_res,
    arguments.offset<dev_ut_states>(),
    6,
    arguments.offset<dev_extrapolation_layer_candidates>());

  state.invoke();

}
